module timer_top (
	input wire sys_clk,
	input wire sys_rst_n,
	input wire tim_psel,
	input wire tim_pwrite,
	input wire tim_penable,
	input wire [11:0] tim_paddr,
	input wire [31:0] tim_pwdata,
	output wire [31:0] tim_prdata,
	input wire [3:0] tim_pstrb,
	output wire tim_pready,
	output wire tim_pslverr,
	output wire tim_int,
	input wire dbg_mode
);
wire rd_en, wr_en, cnt_en, div_en, timer_en;
wire [3:0] div_val;
apb_slave dut (
	.psel (tim_psel),
	.penable (tim_penable),
	.pwrite (tim_pwrite),
	.wr_en (wr_en),
	.rd_en (rd_en)
);
	
regset dut1 (
	.clk (sys_clk),
	.rst_n (sys_rst_n),
	.addr (tim_paddr),
	.wdata (tim_pwdata),
	.wr_en (wr_en),
	.rd_en (rd_en),
	.pstrb (tim_pstrb),
	.dbg_mode (dbg_mode),
	.cnt_en (cnt_en),
	.rdata (tim_prdata),
	.pready (tim_pready),
	.pslverr (tim_pslverr),
	.timer_en (timer_en),
	.div_val (div_val),
	.div_en (div_en),
	.tim_int (tim_int)
);

counter_control dut2 (
	.clk (sys_clk),
	.rst_n (sys_rst_n),
	.div_val (div_val),
	.div_en (div_en),
	.timer_en (timer_en),
	.cnt_en (cnt_en)
);
endmodule

