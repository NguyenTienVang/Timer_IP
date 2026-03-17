module regset (
	input wire clk,
	input wire rst_n,
	input wire [11:0] addr,
	input wire [31:0] wdata,
	input wire rd_en,
	input wire wr_en,
	input wire [3:0] pstrb,
	input wire dbg_mode,
	input wire cnt_en,
	output reg [31:0] rdata,
	output wire pready,
	output wire pslverr,
	output reg timer_en,
	output reg div_en,
	output reg [3:0] div_val,
	output wire tim_int
);


//address registers
parameter ADDR_TCR = 12'h000;
parameter ADDR_TDR0 = 12'h004;
parameter ADDR_TDR1 = 12'h008;
parameter ADDR_TCMP0 = 12'h00C;
parameter ADDR_TCMP1 = 12'h010;
parameter ADDR_TIER = 12'h014;
parameter ADDR_TISR = 12'h018;
parameter ADDR_THCSR = 12'h01C;

//internal signal
wire tcr_wr_sel, tdr0_wr_sel, tdr1_wr_sel, tcmp0_wr_sel, tcmp1_wr_sel, tier_wr_sel, tisr_wr_sel, thcsr_wr_sel;
reg [31:0] TDR0, TDR1, TCMP0, TCMP1;
wire [31:0] tdr0_next, tdr1_next, tcmp0_next, tcmp1_next;
reg  int_en, int_st, halt_req;
wire [63:0] cnt, cnt_next;
wire timer_en_next, div_en_next, div_val_set, int_en_next, int_set, int_clr, int_st_next, halt_req_next;
wire [3:0] div_val_next;
assign tcr_wr_sel = wr_en && (addr == ADDR_TCR);
assign tdr0_wr_sel = wr_en && (addr == ADDR_TDR0);
assign tdr1_wr_sel = wr_en && (addr == ADDR_TDR1);
assign tcmp0_wr_sel = wr_en && (addr == ADDR_TCMP0);
assign tcmp1_wr_sel = wr_en && (addr == ADDR_TCMP1);
assign tier_wr_sel = wr_en && (addr == ADDR_TIER);
assign tisr_wr_sel = wr_en && (addr == ADDR_TISR);
assign thcsr_wr_sel = wr_en && (addr == ADDR_THCSR);
assign pready = 1'b1;
assign pslverr = 1'b0;

//Write Acess
//TCR
assign timer_en_next = tcr_wr_sel ? wdata[0] : timer_en;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		timer_en <= 1'b0;
	end else begin
		timer_en <= timer_en_next;
	end
end

assign div_en_next = tcr_wr_sel ? wdata[1] : div_en;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		div_en <= 1'b0;
	end else begin
		div_en <= div_en_next;
	end
end

assign div_val_set = tcr_wr_sel && (wdata[11:8] < 9);
assign div_val_next [3:0]  = div_val_set ? wdata[11:8] : div_val[3:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		div_val [3:0]  <= 4'b0001;
	end else begin
		div_val [3:0]  <= div_val_next [3:0];
	end
end

//TDR + Counter
assign cnt [63:0] = {TDR1, TDR0};
assign cnt_next [63:0] = cnt [63:0] + 1;
assign tdr0_next [31:0] = tdr0_wr_sel ? wdata [31:0] : cnt_en ? cnt_next [31:0] : TDR0 [31:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		TDR0 [31:0] <= 32'h00000000;
	end else begin
		TDR0 [31:0] <= tdr0_next;
	end
end

assign tdr1_next [31:0] = tdr1_wr_sel ? wdata [31:0] : cnt_en ? cnt_next [63:32] : TDR1 [31:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		TDR1 [31:0] <= 32'h00000000;
	end else begin
		TDR1 [31:0] <= tdr1_next;
	end
end

//TCMP
assign tcmp0_next [31:0] = tcmp0_wr_sel ? wdata [31:0] : TCMP0 [31:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		TCMP0 [31:0] <= 32'hFFFFFFFF;
	end else begin
		TCMP0 [31:0] <= tcmp0_next;
	end
end

assign tcmp1_next [31:0] = tcmp1_wr_sel ? wdata [31:0] : TCMP1 [31:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		TCMP1 [31:0] <= 32'hFFFFFFFF;
	end else begin
		TCMP1 [31:0] <= tcmp1_next;
	end
end

//TIER + TISR + Interrupt
assign int_en_next = tier_wr_sel ? wdata[0] : int_en;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		int_en <= 1'b0;
	end else begin
		int_en <= int_en_next;
	end
end
assign int_set = (cnt[63:0] == {TCMP1, TCMP0});
assign int_clr = (wdata[0] == 1'b1) && tisr_wr_sel;
assign int_st_next = int_clr ? 1'b0 : int_set ? 1'b1 : int_st;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		int_st <= 1'b0;
	end else begin
		int_st <= int_st_next;
	end
end

assign tim_int = int_en && int_st;
//THCSR
assign halt_req_next = thcsr_wr_sel  ? wdata[0] : halt_req;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		halt_req <= 1'b0;
	end else begin
		halt_req <= halt_req_next;
	end
end
//Read access
always @(*) begin
	if (rd_en) begin 
		case (addr) 
			ADDR_TCR: rdata = {20'h0, div_val [3:0], 6'b0, div_en, timer_en};
		   	ADDR_TDR0: rdata = TDR0;
			ADDR_TDR1: rdata = TDR1;
			ADDR_TCMP0: rdata = TCMP0;
			ADDR_TCMP1: rdata = TCMP1;
			ADDR_TIER: rdata = {31'h0, int_en};
			ADDR_TISR: rdata = {31'h0, int_st};
			ADDR_THCSR: rdata = {31'h0, halt_req};
			default: rdata = 32'h0;
		endcase
	end else begin
		rdata = 32'h0;
	end
end

endmodule
