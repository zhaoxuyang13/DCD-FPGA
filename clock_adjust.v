// Generate a clock whose period is N times the period of the reference clock.
module clock_adjust(refclk, resetn, N, outclk);
	input             refclk, resetn;
	input      [31:0] N;
	output reg        outclk;
	reg        [31:0] counter;

	initial begin
		counter <= 0;
		outclk <= 0;
	end

	always @(posedge refclk or negedge resetn) begin
		if (!resetn) begin
			counter <= 0;
			outclk <= 0;
		end
		else begin
			if (counter >= N / 2 - 1) begin
				counter <= 0;
				outclk <= ~outclk;
			end
			else
				counter <= counter + 1;
		end
	end
endmodule

// Generate a clock whose period is 10 times the period of the reference clock.
module clock_adjust_10(refclk, resetn, outclk);
	input             refclk, resetn;
	output reg        outclk;
	reg        [31:0] counter;
	parameter N = 10;

	initial begin
		counter <= 0;
		outclk <= 0;
	end

	always @(posedge refclk or negedge resetn) begin
		if (!resetn) begin
			counter <= 0;
			outclk <= 0;
		end
		else begin
			if (counter >= N / 2 - 1) begin
				counter <= 0;
				outclk <= ~outclk;
			end
			else
				counter <= counter + 1;
		end
	end
endmodule
