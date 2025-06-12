module spi_state(
  input wire clk,               // System clock
  input wire reset,             // Asynchronous reset

  input wire [15:0] datain,     // Data to transmit on MOSI
  input wire spi_miso,          // Data received from slave (MISO)

  output wire spi_cs_l,         // Active-low chip select for SPI
  output wire spi_sclk,         // SPI clock
  output wire spi_data,         // Data output on MOSI
  output wire [4:0] counter,    // Bit counter (from 16 to 0)
  output reg [15:0] received_data // Received data from MISO
);

  // Internal registers
  reg [15:0] shift_reg;         // Holds outgoing data (MOSI shift register)
  reg [4:0] count;              // Bit counter
  reg cs_l;                     // Chip select line (active low)
  reg sclk;                     // SPI clock
  reg [2:0] state;              // FSM state register

  // SPI FSM logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset all internal states and outputs
      shift_reg <= 16'b0;
      count <= 5'd16;
      cs_l <= 1'b1;
      sclk <= 1'b0;
      state <= 0;
      received_data <= 16'b0;
    end else begin
      case (state)
        0: begin
          // Idle state: prepare to start
          sclk <= 1'b0;
          cs_l <= 1'b1;
          state <= 1;
        end

        1: begin
          // Load data and enable SPI communication
          sclk <= 1'b0;
          cs_l <= 1'b0;
          shift_reg <= datain;
          count <= 5'd16;
          state <= 2;
        end

        2: begin
          // Clock low state (prepare for data capture)
          sclk <= 1'b0;
          state <= 3;
        end

        3: begin
          // Clock high: data sampling and shifting
          sclk <= 1'b1;

          if (count > 0) begin
            // Capture MISO bit into corresponding position
            received_data[count - 1] <= spi_miso;

            // Decrement counter
            count <= count - 1;

            // Loop back to prepare next bit
            state <= 2;
          end else begin
            // All bits transferred
            state <= 0;
          end
        end

        default: state <= 0; // Safety fallback
      endcase
    end
  end

  // Output assignments
  assign spi_cs_l = cs_l;                 // Chip select
  assign spi_sclk = sclk;                // SPI clock
  assign spi_data = shift_reg[count - 1]; // Output current bit on MOSI
  assign counter = count;                 // Expose bit counter
endmodule
module spi_slave (
    input wire spi_sclk,       // Clock from master
    input wire spi_cs_l,       // Active-low chip select
    input wire spi_mosi,       // Master Out Slave In
    output wire spi_miso,      // Master In Slave Out
    input wire [15:0] slave_data, // Data to send to master
    output reg [15:0] received_data, // Data received from master
    input wire reset,
    input wire clk             // Local system clock
);

reg [15:0] shift_reg = 16'd0;
reg [3:0] bit_count = 4'd0;

assign spi_miso = shift_reg[15]; // MSB first

always @(posedge spi_sclk or posedge reset) begin
    if (reset) begin
        bit_count <= 4'd0;
        shift_reg <= slave_data;
        received_data <= 16'd0;
    end else if (!spi_cs_l) begin
        // Sample MOSI on rising edge
        received_data <= {received_data[14:0], spi_mosi};

        // Shift out next MISO bit
        shift_reg <= {shift_reg[14:0], 1'b0};
        bit_count <= bit_count + 1;
    end
end

endmodule
