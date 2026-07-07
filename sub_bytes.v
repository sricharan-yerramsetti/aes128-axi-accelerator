module sub_bytes(
    input[127:0] data_in,
    output[127:0] data_out
);
genvar i;
generate
    for(i=0;i<16;i = i + 1) begin
        sbox_lut lut(.in(data_in[8*i +: 8]),.out(data_out[8*i +: 8]));
    end
endgenerate


endmodule