`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2023 03:16:07 PM
// Design Name: 
// Module Name: AD_Model
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AD_Model(
    input  wire                 param_a,                 //amyloid beta enable
    input  wire [          3:0] param_p,                 //p coeffcient 
    input  wire [          7:0] param_thetamem,          // membrane threshold parameter              [SDSP]
    input  wire [          2:0] param_ca_theta1,         // calcium threshold 1parameter              [SDSP]
    input  wire [          2:0] param_ca_theta2,         // calcium threshold 2 parameter             [SDSP]
    input  wire [          2:0] param_ca_theta3,         // calcium threshold 3 parameter             [SDSP]
    input  wire [          4:0] param_caleak,            // calcium leakage strength parameter        [SDSP]
    input  wire                 param_ca_en,             // calcium concentration enable parameter
    input  wire [          2:0] state_calcium,           // calcium concentration state from SRAM     [SDSP]
    input  wire [          4:0] state_caleak_cnt,        // calcium leakage state from SRAM           [SDSP]
    input  wire [          7:0] state_core_next,         // next membrane potential state to SRAM 
    input  wire                 spike_out1,               // neuron spike event signal
    input  wire                 spike_out2,               // neuron spike event signal
    input  wire                 spike_out3,               // neuron spike event signal
    input  wire                 event_tref,              // time reference event signal
    input  wire                 CLK,                     // clock associated with ODIN
    input  wire                 RST,                     //RST for child modules 
    output reg                 v_up_next,               // next SDSP UP condition value signal       [SDSP]
    output reg                 v_down_next,             // next SDSP DOWN condition value signal     [SDSP]
    output reg  [          2:0] state_calcium_next,      // next calcium concentration state to SRAM  [SDSP]
    output reg  [          4:0] state_caleak_cnt_next    // next calcium leakage state to SRAM        [SDSP]
    );
    
    reg ca_leak;
    integer i;
    always @(*) begin
    if (param_a) begin
     v_up_next   <= param_ca_en && (state_core_next >= param_thetamem) && (param_ca_theta1>>1 <= state_calcium_next) && (state_calcium_next < param_ca_theta3);
     v_down_next <= param_ca_en && (state_core_next <  param_thetamem) && (param_ca_theta1>>1 <= state_calcium_next) && (state_calcium_next < param_ca_theta2);
    end 
    end
    
    always @ (*) begin
        if (param_a && ~|param_p) begin
            if (spike_out1 && ~ca_leak && ~&state_calcium) 
            state_calcium_next = state_calcium + 3'b1;
            else if (~spike_out1 && ca_leak && state_calcium != 3'b010)
            state_calcium_next = state_calcium - 3'b1; 
            else if (~spike_out1 && ca_leak && state_calcium == 3'b010)
            state_calcium_next = state_calcium;  
        end 
        if (param_a && |param_p)begin
             //represents small amplitude oscillation case 
            case(param_p)
            3'b1: begin 
                if (~spike_out1 && ca_leak)begin
                  if (state_calcium != 3'b001)
                  state_calcium_next = state_calcium - 3'b1;
                  else if (state_calcium !=3'b011)
                  state_calcium_next = state_calcium + 3'b1;
                  end
                end 
            //represents steady state solution 
            3'b010: begin 
                if (spike_out1 && ca_leak && state_calcium != 3'b011)
                state_calcium_next = state_calcium + 3'b1; 
                else if(~spike_out1 && ca_leak && state_calcium == 3'b011)
                state_calcium_next = state_calcium; 
               end
            3'b011: begin
                if (spike_out3 && ~ca_leak && state_calcium != 3'b011)
                state_calcium_next = state_calcium + 3'b1;
                else if (~spike_out3 && ca_leak && state_calcium != 3'b001) 
                state_calcium_next = state_calcium - 3'b1; 
                
                if (spike_out2 && ~ca_leak && state_calcium != 3'b100) 
                state_calcium_next = state_calcium + 3'b1; 
                else if (~spike_out2 && ~ca_leak && state_calcium != 3'b001)
                state_calcium_next = state_calcium - 3'b1;
                
                if (spike_out1 && ~ca_leak && ~&state_calcium) 
                state_calcium_next = state_calcium + 3'b1;
                else if (~spike_out1 && ca_leak && state_calcium != 3'b001) 
                state_calcium_next = state_calcium- 3'b1;
               end            
           3'b100: begin
            if (spike_out1 && ~ca_leak && ~&state_calcium)//spike out, no leakage, not 111 
                state_calcium_next = state_calcium + 3'b1;
            else if (ca_leak && ~spike_out1 && |state_calcium)//leakage, no spike, not 000
                state_calcium_next = state_calcium - 3'b1;
                end 
          endcase    
        end 
        
    end
    
     always @(*) begin 

        if (param_ca_en && |param_caleak && event_tref)
            if (state_caleak_cnt == (param_caleak - 5'b1)) begin
                state_caleak_cnt_next = 5'b0;
                ca_leak               = 1'b1;
            end else begin
                state_caleak_cnt_next = state_caleak_cnt + 5'b1;
                ca_leak               = 1'b0;
            end
        else begin
            state_caleak_cnt_next = state_caleak_cnt;
            ca_leak               = 1'b0;
        end
    end
    
endmodule