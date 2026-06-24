LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axis_pkg.ALL;
USE work.axis_packet_pkg.ALL;
USE work.axis_packet_conv_pkg.ALL;
ENTITY packet_input_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    packet_in : IN t_axis_packet_64;
    packet_in_ready : OUT STD_LOGIC;

    packet_out : OUT t_axis_packet_64;
    packet_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF packet_input_buffer IS
  SIGNAL s_stream_in : t_axis_64;
  SIGNAL s_stream_out : t_axis_64;
BEGIN
  s_stream_in <= to_axis(packet_in);

  axis_input_buffer_inst : ENTITY work.axis_input_buffer
    PORT MAP(
      clk => clk,
      reset => reset,
      stream_in => s_stream_in,
      stream_in_ready => packet_in_ready,
      stream_out => s_stream_out,
      stream_out_ready => packet_out_ready
    );

  packet_out <= to_packet(s_stream_out);

END ARCHITECTURE structure;