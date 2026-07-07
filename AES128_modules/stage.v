module stage(
    input [127:0] data_in,
    input [127:0] round_key,
    output [127:0] data_out
);
wire[127:0] data_out_0;
wire[127:0] data_out_1;
wire[127:0] data_out_2;


sub_bytes sub_bytes_inst(.data_in(data_in),.data_out(data_out_0));
shift_rows shift_rows_inst(.data_in(data_out_0),.data_out(data_out_1));
mix_columns mix_columns_inst(.data_in(data_out_1),.data_out(data_out_2));
add_round_key add_round_key_inst(.data_in(data_out_2),.data_out(data_out),.round_key(round_key));


endmodule