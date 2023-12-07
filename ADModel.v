`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 08:50:25 PM
// Design Name: 
// Module Name: ADModel
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


module ADModel(
    input wire [2:0] state_calcium_next,
    input wire CLK,
    input wire RST,
    input wire [2:0] param_a,
    input wire [7:0] param_p, 
    input wire [2:0] state_core_next,
    output reg [2:0] new_state_calcium_next
    );
    
    
    //parameters used for differential equations 
    parameter k2 = 0.18;
    parameter kd = 0.00000013;
    parameter ka = 0.75;
    parameter kb = 1;
    parameter m = 4;
    parameter gamma = 5.4;
    parameter gcat = 0.00045;
    parameter Vca = 0.1; 
    parameter ps = 1;
    parameter Vpm = 0.0000028; 
    parameter kpm_squared = 0.00425104;
    parameter a1 = 0.000000003; 
    parameter a2 = 0.02; 
    
    reg [2:0] dc_dt_new;
    reg [63:0] dce_dt; 
    
    wire [2:0] dc_dt;
    wire [8:0] Ca_cubed;
    wire [63:0] kd_ka_a_cubed;
    reg [63:0] kd_ka = kd + ka;
    
    wire [63:0] Jvca;
    wire [63:0] mcat1;
    wire [63:0] hcat1; 
    wire [6:30] hcat2;
    wire [63:0] hcat;
    wire [63:0] mcat; 
    wire [63:0] mcat_squared;
    
    wire [63:0] Jpm;
    wire [63:0] Ca_squared; 
    wire [63:0] a_m;
    
    wire [63:0] Jin; 
    
    //Vryr equation, depends on amyloid-beta 
    exponentation CaCube(
    .power(3), 
    .base(state_calcium_next), 
    .result(Ca_cubed)
    );
    
    exponentation kd_ka_a_Cubed (
    .power(3),
    .base(kd_ka + param_a), 
    .result(kd_ka_a_cubed)
    );
    
    //hcat equation, depends on Vmem AKA state_core_next
    
    exponentation h_cat_1 (
    .power((state_core_next+50)/9), 
    .base(2.71), 
    .result(hcat1) 
    );
    
    exponentation h_cat_2 (
    .power(-(state_core_next+50)/9), 
    .base(2.71), 
    .result(hcat1) 
    );
    
    //mcat equation, depends on Vmem AKA state_core_next
    exponentation m_cat_1 (
    .power(-(state_core_next+56.1)/10), 
    .base(2.71), 
    .result(mcat1) 
    );
    
    exponentation m_cat_squared(
    .power(mcat), 
    .base(2), 
    .result(mcat_squared) 
    );
    
    //Jvca equation 
    assign hcat = 7/(hcat1 + hcat2)+ 1;  
    assign mcat = 1/(1 + mcat1);
    assign Jvca = gcat * hcat1 * mcat_squared * (state_core_next - Vca);
    
    //Jpm
    exponentation CaSquared(
    .power(2), 
    .base(state_calcium_next), 
    .result(Ca_squared)
    );
    
    assign Jpm = (Vpm * Ca_squared)/(kpm_squared + Ca_squared);
    
    //Jin 
    exponentation am(
    .power(m), 
    .base(param_a), 
    .result(a_m)
    );
    
    assign Jin = a1 + a2 * param_p + kb*a_m; 
    
    derivative calcium(
    .inFunct(state_calcium_next), 
    .CLK(CLK),
    .RST(RST),
    .outFunct(dc_dt)
    );
    
    always @(posedge CLK) begin
        kd_ka <= kd + ka * param_a;
        dce_dt <= -gamma*(dc_dt + Jvca + Jpm - Jin);
        dc_dt_new <= dc_dt + (k2*Ca_cubed)/(kd_ka_a_cubed + Ca_cubed)*(0-state_calcium_next);
    end
    
endmodule
