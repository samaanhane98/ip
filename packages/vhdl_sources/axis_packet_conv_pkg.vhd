LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axis_packet_pkg.ALL;
USE work.axis_pkg.ALL;

PACKAGE axis_packet_conv_pkg IS
  FUNCTION to_axis (pkt : t_axis_packet) RETURN t_axis;
  FUNCTION to_packet (axi : t_axis) RETURN t_axis_packet;
END PACKAGE;
PACKAGE BODY axis_packet_conv_pkg IS

  FUNCTION to_axis (pkt : t_axis_packet) RETURN t_axis IS
    VARIABLE result : t_axis(
    tdata(pkt.data'RANGE),
    tkeep(pkt.keep'RANGE),
    tuser(pkt.user'RANGE),
    tmeta(1 DOWNTO 0)
    );
  BEGIN
    result.tvalid := pkt.valid;
    result.tlast := pkt.last;
    result.tdata := pkt.data;
    result.tkeep := pkt.keep;
    result.tuser := pkt.user;
    result.tmeta := pkt.meta_valid & pkt.first; -- assuming meta added to t_axis_packet too
    RETURN result;
  END FUNCTION;

  FUNCTION to_packet (axi : t_axis) RETURN t_axis_packet IS
    VARIABLE result : t_axis_packet(
    data(axi.tdata'RANGE),
    keep(axi.tkeep'RANGE),
    user(axi.tuser'RANGE)
    );
  BEGIN
    result.valid := axi.tvalid;
    result.last := axi.tlast;
    result.data := axi.tdata;
    result.keep := axi.tkeep;
    result.user := axi.tuser;
    result.meta_valid := axi.tmeta(1);
    result.first := axi.tmeta(0);
    RETURN result;
  END FUNCTION;
END PACKAGE BODY axis_packet_conv_pkg;