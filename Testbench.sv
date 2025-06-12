`timescale 1ns / 1ps

module tb_spi_master_slave;

  // Clock & Reset
  reg clk;
  reg reset;

  // SPI Lines (shared between Master and Slave)
  wire spi_cs_l;
  wire spi_sclk;
  wire spi_mosi;
  wire spi_miso;

  // Master Signals
  reg [15:0] master_datain;
  wire [15:0] master_received_data;
  wire [4:0] master_counter;

  // Slave Signals
  reg [15:0] slave_data;
  wire [15:0] slave_received_data;

  // Instantiate SPI Master
  spi_state master (
    .clk(clk),
    .reset(reset),
    .datain(master_datain),
    .spi_cs_l(spi_cs_l),
    .spi_sclk(spi_sclk),
    .spi_data(spi_mosi),
    .spi_miso(spi_miso),
    .counter(master_counter),
    .received_data(master_received_data)
  );

  // Instantiate SPI Slave
  spi_slave slave (
    .spi_sclk(spi_sclk),
    .spi_cs_l(spi_cs_l),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .slave_data(slave_data),
    .received_data(slave_received_data),
    .reset(reset),
    .clk(clk)  // Unused in slave for now
  );

  // Clock generation
  always #5 clk = ~clk;

  // VCD for waveform
  initial begin
    $dumpfile("spi_master_slave.vcd");
    $dumpvars(0, tb_spi_master_slave);
  end

  // Test sequence
  initial begin
    clk = 0;
    reset = 1;
    master_datain = 16'hA5F0;   // Data to send from master
    slave_data    = 16'h5A3C;   // Data to send from slave

    #10 reset = 0;

    #400; // wait for SPI transaction to finish

    // Display result
    $display("Master received: %h", master_received_data);
    $display("Slave  received: %h", slave_received_data);

    $finish;
  end

endmodule
