module mix_columns(
    input[127:0] data_in,
    output[127:0] data_out
);

single_col_mix mix0(.in(data_in[127:96]),.out(data_out[127:96]));
single_col_mix mix1(.in(data_in[95:64]),.out(data_out[95:64]));
single_col_mix mix2(.in(data_in[63:32]),.out(data_out[63:32]));
single_col_mix mix3(.in(data_in[31:0]),.out(data_out[31:0]));

endmodule