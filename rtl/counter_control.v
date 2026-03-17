module counter_control (
	input wire clk,
	input wire rst_n,
	input wire [3:0] div_val,
	input wire div_en,
	input wire timer_en,
	output wire cnt_en
);
//internal signal
wire [7:0] int_cnt_next;
reg [7:0] int_cnt, limit;
wire cnt_rst;
always @(*) begin
	limit = (div_val [3:0] == 4'd0) ? 8'd1 : ((8'd1 << div_val) - 1);
end

assign cnt_rst = (!timer_en || !div_en || (int_cnt [7:0] == limit [7:0] ));

assign int_cnt_next [7:0] = cnt_rst ? 8'b0 : (timer_en && div_en && (div_val != 0)) ? (int_cnt[7:0] + 1) : (int_cnt[7:0]);
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		int_cnt [7:0] <= 8'b00000001;
	end else begin
		int_cnt [7:0] <= int_cnt_next [7:0];
	end
end

assign cnt_en = (!div_en && timer_en) || ((div_val != 0) && div_en && timer_en && (int_cnt == limit)) || ((div_val == 0) && div_en && timer_en);
endmodule
