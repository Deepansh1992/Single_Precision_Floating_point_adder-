//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 09/20/2018 12:11:27 AM
//// Design Name: 
//// Module Name: spp_adder_pipelined
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////
 
 
module spp_adder_pipelined #(parameter opcode_width = 'd4)( clk,a, b, c, reset_n, we); 
input 				we; 
input 				reset_n; 
input 		[31:0]	a; 
input 		[31:0]	b; 
output  	[31:0]	c; 
input clk ; 

    localparam exponent_a_greater = 4'd1; 
    localparam exponent_b_greater = 4'd2; 
    localparam exponents_equal    = 4'd3;
 

	reg 		sign_a 	  ; 
	reg [7:0]	exponent_a; 
	reg [23:0]	mentissa_a; 
    
	reg 		sign_b    ; 
	reg [7:0]	exponent_b; 
	reg [23:0]	mentissa_b;
  

 	//-------------------------------------------------------Exponent Compare ----------------- Pipe Line Stage 1
 	reg [7:0] shift_required; 
 	reg   [opcode_width-1:0] opcode; 
 	reg [23:0] mentissa_a_reg;
 	reg [23:0] mentissa_b_reg;
 	reg sign_a_reg;
    reg sign_b_reg;
    reg [7:0] exponent_taken; 
    
 	always @(posedge clk or negedge reset_n) begin : value_assignment
        if (!reset_n) begin 
            sign_a 	    <= 1'b0; 
            exponent_a  <= 1'b0; 
            mentissa_a  <= 1'b0; 
            sign_b      <= 1'b0;
            exponent_b  <= 1'b0; 
            mentissa_b  <= 1'b0; 
        end 
        else begin 
            sign_a 	 	<=  a[31]   ; 
            exponent_a  <=  a[30:23]; 
            mentissa_a  <=  {1'b1, a[22:0]} ; 
            sign_b      <=  b[31]   ; 
            exponent_b  <=  b[30:23]; 
            mentissa_b  <=  {1'b1, b[22:0]} ;
       end 
    end // value_assign 
    

 	always @(posedge clk or negedge reset_n) begin : exponent_compare
 		if(!reset_n) begin
 			shift_required <= 0;
 			opcode         <= 0;
 		end 
 		else begin 
	 		if (exponent_a > exponent_b) begin
	 			shift_required <= exponent_a - exponent_b;
	 			opcode <= exponent_a_greater; 
	 			exponent_taken <= exponent_a; 
	 		end // else if (exponent_a > exponent_b)
	 		else if (exponent_b > exponent_a) begin 
	 			shift_required <= exponent_b - exponent_a; 
	 			opcode <= exponent_b_greater ;
	 			exponent_taken <= exponent_b;  
	 		end // else if (exponent_b < exponent_a)
	 		else if (exponent_a == exponent_b) begin 
	 			shift_required <= 0; 
	 			opcode <= exponents_equal;
	 			exponent_taken <= exponent_a;
	 		end // else if (exponent_a == exponent_b) 
	 	end
	 	mentissa_a_reg <= mentissa_a;
	 	mentissa_b_reg <= mentissa_b;
	 	sign_a_reg     <= sign_a; 
	 	sign_b_reg     <= sign_b;              
 	end
 
//----------------------------------------------------------mentissa alignement ----------------- Pipe Line Stage 2
	reg			mentissa_a_shifted 	; 
	reg 		mentissa_b_shifted	; 
	reg 		no_shift;  
	reg [23:0]  aligned_mentissa_b;
    reg [23:0]  aligned_mentissa_a;
    reg         sign_a_reg_2 ;
    reg         sign_b_reg_2 ;
    reg [7:0] exponent_taken_reg;  
    
 	always @(posedge clk or negedge reset_n) begin : Mentissa_allignment  
 		if(!reset_n) begin
 			aligned_mentissa_b   <= 0;
 			aligned_mentissa_a   <= 0;             
 			mentissa_a_shifted <= 0;
 			mentissa_b_shifted <= 0;
 			no_shift		   <= 0;  
 		end 
 		else begin
 			if(opcode == exponent_a_greater) begin
 			 	aligned_mentissa_b <= mentissa_b_reg >> shift_required; 
 			 	aligned_mentissa_a <= mentissa_a_reg; 
 			 end 
 			 else if(opcode == exponent_b_greater) begin
 			 	aligned_mentissa_a <= mentissa_a_reg >> shift_required; 
 			 	aligned_mentissa_b <= mentissa_b_reg; 
 			 end
 			 else if (opcode == exponents_equal) begin
 			 	aligned_mentissa_a <= mentissa_a_reg;
 			 	aligned_mentissa_b <= mentissa_b_reg; 
 			 end
 		end
 		sign_a_reg_2     <= sign_a_reg;
 		sign_b_reg_2     <= sign_b_reg;
 		exponent_taken_reg <= exponent_taken ;
 	  end 

 	//------------------------------------------------mentissa_compare ----------------- Pipe Line Stage 3
	reg         magnitude = 0; 

 	reg   [23:0]  mentissa_add_a;
 	reg   [23:0]  mentissa_add_b;
    reg   [7:0]   exponent_taken_reg_1; 
    reg           sign_taken; 
 	always @(posedge clk or negedge reset_n) begin : mentissa_compare
 		if(!reset_n) begin
 			mentissa_add_a <= 'd0;
 			mentissa_add_b <= 'd0; 
 		end 
 		else begin
            if (aligned_mentissa_a > aligned_mentissa_b) begin 
                sign_taken     <= sign_a_reg_2;     
                if (sign_a_reg_2 != sign_b_reg_2) begin 
                    magnitude <= 1'b1; 
                    mentissa_add_b <= ~aligned_mentissa_b + 1'b1; 
                    mentissa_add_a <= aligned_mentissa_a; 
                    
                end
                else begin 
                    magnitude <= 1'b0; 
                    mentissa_add_b <= aligned_mentissa_b; 
                    mentissa_add_a <= aligned_mentissa_a;
                end 
            end 
            else if (aligned_mentissa_b > aligned_mentissa_a) begin 
                sign_taken <= sign_b_reg_2; 
                if (sign_a_reg_2 != sign_b_reg_2) begin 
                    magnitude <= 1'b1; 
                    mentissa_add_a <= ~aligned_mentissa_a + 1'b1;
                    mentissa_add_b <= aligned_mentissa_b;         
                end
                else begin 
                    magnitude <= 1'b0;                     
                    mentissa_add_b <= aligned_mentissa_b;
                    mentissa_add_a <= aligned_mentissa_a;        
                end 
            end 
            else if (aligned_mentissa_a == aligned_mentissa_b ) begin 
                sign_taken <= sign_a_reg_2;
                if (sign_a_reg_2 != sign_b_reg_2) begin 
                    magnitude <= 1'b1; 
                    mentissa_add_b <= ~aligned_mentissa_b + 1'b1;
                    mentissa_add_a <= aligned_mentissa_a;         
                end
                else begin 
                    magnitude <= 1'b0; 
                    mentissa_add_b <= aligned_mentissa_b;
                    mentissa_add_a <= aligned_mentissa_a;        
                end 
            end 
         end 
         exponent_taken_reg_1 <=exponent_taken_reg;
 	end // mentissa_compare
 	
 	
 	
 	
// 	//----------------------mentissa addition  ----------------- Pipe Line Stage 4
 	localparam left = 1'b0;
 	localparam right = 1'b1; 
 	reg 	   direction; 
 	reg [24:0] added_mentissa; 
 	reg [24:0] added_mentissa_reg_1;
 	reg [7:0]  shift_count = 8'd0; 
 	reg [7:0] exponent_taken_reg_2, exponent_taken_reg_3; 
 	reg       sign_taken_reg,direction_reg; 
	reg       overflowed_signed; 
	reg [23:0] normalize, added_mentissa_z; 
	
//---------------------------------Normalization 1---------------------------------------------------
 	always @(mentissa_add_b or mentissa_add_a ) begin : adder
 	    if (magnitude) begin 
 	      added_mentissa ={1'b0, mentissa_add_a + mentissa_add_b};
 	      overflowed_signed= 1'b1; 
 	    end
 	    else begin
 	      added_mentissa =  mentissa_add_a + mentissa_add_b;
 	      overflowed_signed = 0; 
 	    end 
 	end : adder
//---------------------------------------------------------------------------------------
 	always @(posedge clk or negedge reset_n) begin : normalization_1
 		if(!reset_n) begin
 			added_mentissa <= 'd0;
 		end 
 		else begin
             if (added_mentissa[24:23]>2'b1) begin 
                 direction <=right; 
                 shift_count <= 1'b1; 
             end 
             else if (added_mentissa[24:23]  == 2'd1) begin 
                shift_count <= 0; 

             end 
             else if (!added_mentissa[23])begin
                direction <=left; 
                shift_count <= 1'b0;  
                added_mentissa_z <= added_mentissa[23:0]; 
             end
 		end 
 		exponent_taken_reg_2 <= exponent_taken_reg_1;
 		sign_taken_reg       <= sign_taken; 
 		added_mentissa_reg_1 <= added_mentissa ;
        exponent_taken_reg_2 <= exponent_taken_reg_1;
        exponent_taken_reg_3 <= exponent_taken_reg_2;
 	end : normalization_1
 	
 	always @(*) begin 
        if (direction == left) begin 
              while (!added_mentissa_z[23]) begin 
                 direction = left; 
                 shift_count     = shift_count + 1; 
                 added_mentissa_z =  added_mentissa_z <<  1'b1;
             end // while (!added_mentissa[23])
             normalize = added_mentissa_z; 
       end 
       else 
             normalize = 'd0;          
 	end 
 //--------------------------------Normalization 2----------------------------------------------------------------	
 
 	reg [24:0] added_mentissa_reg; 
 	reg [24:0] added_mentissa_normalize; 
 	reg [7:0] exponent_normalize; 


 	always @(posedge clk or negedge reset_n) begin : normalization_2
 		if(!reset_n) begin
 			added_mentissa_reg <= 0;
 		end else begin
 			if (direction == right) begin 
 			  exponent_normalize <= exponent_taken_reg_2 + shift_count;  		        
              added_mentissa_normalize <=  added_mentissa_reg_1 >>  shift_count;
 			end 
 			else if (direction == left) begin 
	          exponent_normalize <= exponent_taken_reg_2 - shift_count; 
	          added_mentissa_normalize <=  {1'b0, normalize};
 		    end 
 		    else  begin 
                exponent_normalize <= exponent_taken_reg_2 + shift_count;  
                 added_mentissa_normalize <=  added_mentissa_reg_1 ;		        
            end  
 		end
 	end // normalization_2
 	assign c = {sign_taken_reg,exponent_normalize ,added_mentissa_normalize[22:0]}; 
endmodule