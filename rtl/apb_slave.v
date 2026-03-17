module apb_slave (
	input wire psel,
	input wire penable,
	input wire pwrite,
	output wire wr_en,
	output wire rd_en
);

assign wr_en = psel && pwrite && penable;
assign rd_en = psel && ~pwrite && penable;

endmodule
