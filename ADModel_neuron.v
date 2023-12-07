`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2023 01:57:05 AM
// Design Name: 
// Module Name: ADModel_neuron
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


module ADModel_neuron(
    input  wire                 param_a,                 //amyloid beta enable
    input  wire [          3:0] param_p,                 //p coeffcient 
    
    input  wire [          6:0] param_leak_str,          // leakage strength parameter
    input  wire                 param_leak_en,           // leakage enable parameter
    input  wire [          7:0] param_thr,               // neuron firing threshold parameter
    input  wire                 param_ca_en,             // calcium concentration enable parameter    [SDSP]
    input  wire [          7:0] param_thetamem,          // membrane threshold parameter              [SDSP]
    input  wire [          2:0] param_ca_theta1,         // calcium threshold 1 parameter             [SDSP]
    input  wire [          2:0] param_ca_theta2,         // calcium threshold 2 parameter             [SDSP]
    input  wire [          2:0] param_ca_theta3,         // calcium threshold 3 parameter             [SDSP]
    input  wire [          4:0] param_caleak,            // calcium leakage strength parameter        [SDSP]
    
    input  wire [          7:0] state_core,              // membrane potential state from SRAM 
    output wire [          7:0] state_core_next,         // next membrane potential state to SRAM
    input  wire [          2:0] state_calcium,           // calcium concentration state from SRAM     [SDSP]
    output wire [          2:0] state_calcium_next,      // next calcium concentration state to SRAM  [SDSP]
    input  wire [          4:0] state_caleak_cnt,        // calcium leakage state from SRAM           [SDSP]
    output wire [          4:0] state_caleak_cnt_next,   // next calcium leakage state to SRAM        [SDSP]

    
    input  wire [          2:0] syn_weight,              // synaptic weight
    input  wire                 syn_sign,                // inhibitory (!excitatory) configuration bit
    input  wire                 syn_event,               // synaptic event trigger
    input  wire                 time_ref,                // time reference event trigger
    
    output wire                 v_up_next,               // next SDSP UP condition value              [SDSP]
    output wire                 v_down_next,             // next SDSP DOWN condition value            [SDSP]
    output wire [          6:0] event_out1,              // neuron spike event output  
    output wire [          6:0] event_out2,             // neuron spike event output  
    output wire [          6:0] event_out3              // neuron spike event output
    );
    
    wire       event_leak, event_tref;
    wire       event_inh;
    wire       event_exc;

    assign event_leak =  syn_event  & time_ref;
    assign event_tref =  event_leak;
    assign event_exc  = ~event_leak & (syn_event & ~syn_sign);
    assign event_inh  = ~event_leak & (syn_event &  syn_sign);

        
    AD_Model AD_0 (
        .param_a(param_a),
        .param_p(param_p),
        .param_ca_en(param_ca_en),
        .param_thetamem(param_thetamem),
        .param_ca_theta1(param_ca_theta1),
        .param_ca_theta2(param_ca_theta2),
        .param_ca_theta3(param_ca_theta3),
        .param_caleak(param_caleak),
        .state_calcium(state_calcium),
        .state_caleak_cnt(state_caleak_cnt),
        .state_core_next(state_core_next),
        .spike_out1(event_out1[6]),
        .spike_out2(event_out2[6]), 
        .spike_out3(event_out3[6]),
        .event_tref(event_tref),
        .v_up_next(v_up_next),
        .v_down_next(v_down_next),
        .state_calcium_next(state_calcium_next),
        .state_caleak_cnt_next(state_caleak_cnt_next)
    );

    ADModel_neuronstate neuron_state_0 (
        .param_leak_str(param_leak_str),
        .param_leak_en(param_leak_en),
        .param_thr(param_thr),
        .state_core(state_core),
        .event_leak(event_leak),
        .event_inh(event_inh),
        .event_exc(event_exc),
        .syn_weight(syn_weight),
        .state_core_next(state_core_next),
        .event_out1(event_out1),
        .event_out2(event_out2),
        .event_out3(event_out3)
    );
endmodule
