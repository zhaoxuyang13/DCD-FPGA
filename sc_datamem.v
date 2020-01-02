module sc_datamem (
	addr,datain,dataout,we,clock,mem_clk,dmem_clk,	
	out_port0,out_port1,out_port2,led,in_port0,in_port1,mem_dataout,io_read_data
);
 
   input  [31:0]  addr;
	input  [31:0]  datain;
	input [4:0] in_port0,in_port1;
   input          we, clock,mem_clk;
   output [31:0]  dataout;
   output         dmem_clk;
	output [31:0] out_port0,out_port1,out_port2;
	
	output [31:0] mem_dataout;
	output [31:0] io_read_data;
   output [9:0] led;
   wire           dmem_clk;    
   wire           write_enable; 
	wire [31:0] dataout;
	wire [31:0] mem_dataout;
	wire write_data_enable;
	wire write_io_enable;
	
   assign         write_enable = we & ~clock; 
   assign         dmem_clk = mem_clk & ( ~ clock) ; 
	
	//100000-111111:I/O ; 000000-011111:data
	
	mux2x32 io_data_mux(mem_dataout,io_read_data,addr[7],dataout);
   lpm_ram_dq_dram  dram(addr[6:2],dmem_clk,datain,write_data_enable,mem_dataout );
	
endmodule	