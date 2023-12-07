`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2023 11:30:31 PM
// Design Name: 
// Module Name: ADModel_neuronstate
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


module ADModel_neuronstate(
    input  wire [          6:0] param_leak_str,         // leakage strength parameter
    input  wire [          3:0] param_p,
    input  wire                 param_leak_en,          // leakage enable parameter
    input  wire [          7:0] param_thr,              // neuron firing threshold parameter
    input  wire [          7:0] state_core,             // membrane potential state from SRAM 
    input  wire                 event_leak,             // leakage type event
    input  wire                 event_inh,              // excitatory type event
    input  wire                 event_exc,              // inhibitory type event
    input  wire [          2:0] syn_weight,             // synaptic weight
    output reg [          7:0] state_core_next,        // next membrane potential state to SRAM 
    output wire [          6:0] event_out1,              // neuron spike event output  
    output wire [          6:0] event_out2,             // neuron spike event output  
    output wire [          6:0] event_out3              // neuron spike event output  
    );


    reg  [7:0] state_core_next_i;
    wire [7:0] state_leak, state_inh, state_exc;
    reg       spike_out1, spike_out2, spike_out3; 

    assign event_out1     = {spike_out1, 3'b000, 3'b0};
    assign event_out2     = {spike_out2, 3'b000, 3'b0};
    assign event_out3     = {spike_out3, 3'b000, 3'b0};
    
    always @ (param_p) begin
        if (param_p == 4'b0011) begin 
            spike_out1 = (state_core_next_i >= param_thr);
            spike_out2       = (state_core_next_i >= (param_thr>>1)); 
            spike_out3       = (state_core_next_i >= ((param_thr>>1) + (param_thr>>2)));
                if (spike_out1 || spike_out2 || spike_out3)
                    state_core_next = state_core_next_i;
                else
                state_core_next = 8'd0;
                
        end else
            spike_out1 = (state_core_next_i >= param_thr);
            spike_out2       = 0; 
            spike_out3       = 0;
           state_core_next = (spike_out1? 8'd0 : state_core_next_i); 
    end  

    always @(*) begin 

            if (event_leak && param_leak_en)
                if (state_core >= state_leak)
                    state_core_next_i = state_leak;
                else
                    state_core_next_i = 8'b0;
            else if (event_inh)
                if (state_core >= state_inh)
                    state_core_next_i = state_inh;
                else
                    state_core_next_i = 8'b0;
            else if (event_exc)
                if (state_core <= state_exc) //voltage less than excitatory voltage 
                    state_core_next_i = state_exc;
                else
                    state_core_next_i = 8'hFF;
            else 
                state_core_next_i = state_core;
    end

    assign state_leak = (state_core - {1'b0,param_leak_str});
    assign state_inh  = (state_core - {5'b0,syn_weight});
    assign state_exc  = (state_core + {5'b0,syn_weight});

endmodule 
