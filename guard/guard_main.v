// Main module of the device.
// States:
//   0 -> initial (welcome), waiting for retrieving
//   1 -> address set, waiting for password
//   2 -> password set, show information   ->3   ->0
//   3 -> new value set, waiting for new password -> 4 ->0
//   4 -> new password set
// Key usage:
//   key3: set (go to state 3 directly)
//   key2: finish (the finish option in 2,3)
//   key1: comfirm (go to next state, or finally finish)
//   key0: reset (reset all states, return to state 0)
module guard_main(resetn, mclock, sw, key, hex5, hex4, hex3, hex2, hex1, hex0, led);
	input         mclock, resetn;
	input  [9:0]  sw;
	input  [3:1]  key;
	output [6:0]  hex5, hex4, hex3, hex2, hex1, hex0;
	output [9:0]  led;
	
	// Clock ratio for 1s clock and 0.5s clock.
	parameter secclk_N = 5000000;
	parameter halfsecclk_N = 2500000;

	// Sevenseg and LED codes.
	parameter code_off = 7'b1111111; // Sevenseg all off.
	parameter code_hf = 7'b0111111; // '-'
	parameter code_A = 7'b0001000;
	parameter code_C = 7'b1000110;
	parameter code_D = 7'b0100001;
	parameter code_F = 7'b0001110;
	parameter code_G = 7'b1000010;
	parameter code_H = 7'b0001001;
	parameter code_I = 7'b1111001;
	parameter code_L = 7'b1000111;
	parameter code_O = 7'b1000000;
	parameter code_P = 7'b0001100;
	parameter code_S = 7'b0010010;
	parameter code_U = 7'b1000001;
	parameter led_off = 10'b0000000000; // LED all off.
	parameter led_on = 10'b1111111111; // LED all on.

	wire key3 = key[3];
	wire key2 = key[2];
	wire key1 = key[1];
   reg  key3_last,key2_last,key1_last;
   wire          clock,second_clock, flash_clock, pf_status;
	//generate base clock
	clock_adjust base_clk(mclock,resetn,2,clock);
	// Generate 1s clock and 0.5s clock.
	clock_adjust sec_clk(mclock, resetn, secclk_N, second_clock);
	clock_adjust halfsec_clk(mclock, resetn, halfsecclk_N, flash_clock);

	// Welcome LED. (For states 0, 1 and 7)
	// display_welcome disp_welcome(flash_clock, resetn, led_wlcm);
	
	reg [2:0] state;

	reg [7:0] addr;
	reg [6:0] addr_hex0,addr_hex1;
	wire [7:0] address_display;
	wire [6:0] address_hex0,address_hex1;
	assign address_display = {sw[7:0]}; // display address as the lower 6 bits of switch
	out_port_seg address_segs(address_display,address_hex1,address_hex0);

	reg [7:0] pwd;
	reg [6:0] pwd_hex0,pwd_hex1;
	wire [7:0] passwd_display,passwd_read;
	wire [6:0] passwd_hex0,passwd_hex1;
	assign passwd_display = {sw[7:0]}; // display address as the lower 8 bits of switch	
	out_port_seg passwd_segs(passwd_display,passwd_hex1,passwd_hex0);
	
	reg [7:0] val;
	reg [6:0] val_hex0,val_hex1;
	wire [7:0] value_display,value_read;
	wire [6:0] value_hex0,value_hex1,value_read_hex0,value_read_hex1;
	assign value_display = {sw[7:0]}; // display address as the lower 8 bits of switch	
	out_port_seg value_segs(value_display,value_hex1,value_hex0);
	out_port_seg value_read_segs(value_read,value_read_hex1,value_read_hex0);
	
	wire [7:0] new_pass,new_value;
	wire write_passwd_enable,write_value_enable;
	assign write_value_enable = (state == 3);// && ((!key1 && key1_last) || (!key2 && key2_last));
	assign write_passwd_enable = (state == 4);// && ((!key1 && key1_last) || (!key2 && key2_last));
	assign new_value = value_display;
	assign new_pass = passwd_display;
	
    data_memory  data_space(addr,mclock,new_value,write_value_enable,value_read);
	data_memory  passwd_space(addr,mclock,new_pass,write_passwd_enable,passwd_read);
	
	// Multiplexers to select output for sevensegs and LEDs according to current state.
	mux8x7 select_hex1(address_hex1, addr_hex1, addr_hex1,addr_hex1, addr_hex1,code_A, code_A,code_A, state, hex1);
	mux8x7 select_hex0(address_hex0, addr_hex0, addr_hex0,addr_hex0, addr_hex0,code_A, code_A,code_A, state, hex0);
	mux8x7 select_hex3(code_P, passwd_hex1, pwd_hex1,pwd_hex1, passwd_hex1,code_P, code_P,code_P, state, hex3);
	mux8x7 select_hex2(code_P, passwd_hex0, pwd_hex0,pwd_hex0, passwd_hex0,code_P, code_P,code_P, state, hex2);
	mux8x7 select_hex5(code_U, code_U, val_hex1,value_hex1, val_hex1,code_U, code_U,code_U, state, hex5);
	mux8x7 select_hex4(code_U, code_U, val_hex0,value_hex0, val_hex0,code_U, code_U,code_U, state, hex4);


	// mux8x10 select_led(led_wlcm, led_wlcm, led_on, led_progress, led_pass, led_success, led_off, led_wlcm, state, led);
    assign led = sw;

	always @(posedge clock or negedge resetn) begin
		if (!resetn) begin // reset or back
			state <= 0;
			addr <= 0;
			val <= 0;
			pwd <= 0;
		end else begin // posedge of clock
			case (state) // state machine
				0: begin
					val_hex0 <= 0;
					val_hex1 <= 0;
					pwd_hex1 <= 0;
					pwd_hex0 <= 0;
					if (!key1 && key1_last) begin
						addr <= sw[5:0];
						addr_hex0 <= address_hex0;
						addr_hex1 <= address_hex1;
						state = 1;
                	end
				end
				1: begin
					if(!key1 && key1_last) begin
						if(passwd_read == sw[7:0])begin
							pwd = sw[7:0];
							pwd_hex0 = passwd_hex0;
							pwd_hex1 = passwd_hex1;
							val_hex0 = value_read_hex0;
							val_hex1 = value_read_hex1;
							state = 2;
						end else begin
							state = 0;
						end
					end
				end
				2: begin
					if(!key1 && key1_last) begin
						state = 3;
					end else begin
						if(!key2 && key2_last)
							state = 0;
					end
				end
				3: begin
                  if(!key1 && key1_last) begin
						val <= sw[7:0];
						val_hex1 <= value_hex1;
						val_hex0 <= value_hex0;
						state = 4;
				  end else if (!key2 && key2_last) begin
					  state = 0;
				  end
				end
				4: begin
					if ((!key1 && key1_last) || (!key2 && key2_last))begin
						state = 0;
				 	end
				end
			endcase

			// Store last states of key3 and key2 (resolve long pressing problem).
			key3_last <= key3;
			key2_last <= key2;
            key1_last <= key1;
		end
	end
endmodule

module mux8x7(a0, a1, a2, a3, a4, a5, a6, a7, s, y);
    input [6:0] a0, a1, a2, a3, a4, a5, a6, a7;
    input [2:0] s;
    output reg [6:0] y;
    always @(*)
    case (s)
    3'b000: y = a0;
    3'b001: y = a1;
    3'b010: y = a2;
    3'b011: y = a3;
    3'b100: y = a4;
    3'b101: y = a5;
    3'b110: y = a6;
    3'b111: y = a7;
    endcase
endmodule

module out_port_seg(in,out1,out0);
	input [7:0] in;
	output [6:0] out1,out0;
	
	reg [3:0] num1,num0;

	sevenseg display_1( num1, out1 );
	sevenseg display_0( num0, out0 );
	
	always @ (in)
	begin
		num1 = ( in / 10 ) % 10;
		num0 = in % 10;
	end
	
endmodule