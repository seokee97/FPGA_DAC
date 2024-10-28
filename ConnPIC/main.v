`timescale 1ns / 1ps

module main (
	input wire clk,
	input wire rst,
	input wire rx,  // PIC에서 오는 TX 신호 (수신 신호)
	input wire [9:0] pic_data,  // PIC에서 보낸 10비트 데이터 입력
	output reg tx,  
	output reg cs_n,
	output reg sck, 
	output reg mosi,
	output reg test_pin1,
	output reg test_pin2,
	output reg test_pin3,
	output reg test_pin4
);

	reg [1:0] state;
	reg [4:0] bit_count;
	reg [15:0] spi_data;  // SPI로 전송할 16비트 데이터
	reg [11:0] dac_data;  // 12비트 DAC 데이터
	reg sck_enable;
	reg [7:0] clk_div;
	
	// 클럭 분주기: SPI 클럭 속도 조절
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			clk_div <= 8'd0;
		end else if (clk_div == 8'd255) begin
			clk_div <= 8'd0;
			sck_enable <= 1'b1;
		end else begin
			clk_div <= clk_div + 1;
			sck_enable <= 1'b0;
		end
	end
	
    // SPI 및 통신 상태 제어
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			state <= 2'b00;
			cs_n <= 1'b1;   
			sck <= 1'b0;   
			mosi <= 1'b0; 
			bit_count <= 0;
			tx <= 1'b1; 
			dac_data <= 12'd0;
			test_pin1 <= 12'd0;
			test_pin2 <= 12'd0;
			test_pin3 <= 12'd0;
			test_pin4 <= 12'd0;
		end else begin
			case (state)
				2'b00: begin  
					if (rx == 1) begin  
						//dac_data <= {2'b00, pic_data};
						tx<= 1'b0;
						state <= 2'b01;  
					end
				end
				2'b01: begin  
					cs_n <= 1'b0;  
					test_pin1 <= pic_data;
					spi_data <=  16'b0101000000000000 + pic_data; 
					bit_count <= 15;  
					state <= 2'b10; 
				end
				2'b10: begin  
					if (sck_enable) begin
						sck <= ~sck; 
						if (!sck) begin
							mosi <= spi_data[bit_count];  
						end else if (bit_count == 0) begin
							state <= 2'b11;  
						end else begin
							bit_count <= bit_count - 1;  
						end
					end
				end
				2'b11: begin 
					cs_n <= 1'b1;  
					tx <= 1'b1;  
					state <= 2'b00; 
				end
			endcase
		end
	end
endmodule
