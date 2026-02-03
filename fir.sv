module fir #(parameter N = 20)
	(input logic signed [N-1:0] in,
       input logic input_ready, ck, rst ,
       output logic signed [N-1:0] out,
       output logic output_ready);

typedef logic signed [N-1:0] sample_array;
sample_array samples [0:N-1];

// generate coefficients from Octave/Matlab
// code used to generate disp(sprintf('%d,',round(fir1(15,0.5)*32768)))

const sample_array coefficients [0:N-1] =
     '{991,1452,-2776,-5220,9135,15110,-24361,-40071,74079,233805,233805,74079,-40071,-24361,15110,9135,-5220,-2776,1452,991};


logic unsigned [($clog2(N))-1:0] address; //clog2 of 16 is 4 why?

logic signed [((2*N)-1):0] sum;

typedef enum logic [1:0] {waiting, loading, processing, saving} state_type;
state_type state, next_state;
logic load, count, reset_accumulator;


always_ff @(posedge ck)
  if (load)
    begin
    for (int i= (N-1); i >= 1; i--)
      samples[i] <= samples[i-1];
    samples[0] <= in;
    end 
  

// accumulator register
always_ff @(posedge ck)
  if (reset_accumulator)
    sum <= '0;
  else
    sum <= sum + samples[address] * coefficients[address];
 
// output register
always_ff @(posedge ck)
  if (output_ready)
    out <= sum[((2*N)-2):N-1];


// address counter
always_ff @(posedge ck) begin
  if(reset_accumulator)
        address <= '0;
  else begin
	if(count)
		address <= address + 1;
	end
end
	
// controller state machine 
always_ff @(posedge ck, posedge rst) begin
  if(rst)
        state <= waiting;
	else 
		state <= next_state;
	end
	
always_comb begin: COM
    reset_accumulator = '0;
    load = '0;
    count = '0;
    output_ready = '0;
    next_state = state;

    unique case(state)
        waiting: begin
            reset_accumulator = '1;
            if(input_ready)
                next_state = loading;
        end

        loading: begin
            load = '1;
            reset_accumulator = '1;
            next_state = processing;
        end

        processing: begin
            count = '1;
            if(address == (N-1))
                next_state = saving;
        end

        saving: begin
            output_ready = '1;
            next_state = waiting;
        end
endcase
end
endmodule
