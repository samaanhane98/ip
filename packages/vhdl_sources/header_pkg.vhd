LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE header_pkg IS

  -- ============================================================
  --  Common type aliases
  -- ============================================================
  SUBTYPE byte_t IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE word16_t IS STD_LOGIC_VECTOR(15 DOWNTO 0);
  SUBTYPE word32_t IS STD_LOGIC_VECTOR(31 DOWNTO 0);
  SUBTYPE mac_addr_t IS STD_LOGIC_VECTOR(47 DOWNTO 0); -- 6 bytes
  SUBTYPE ipv4_addr_t IS STD_LOGIC_VECTOR(31 DOWNTO 0); -- 4 bytes

  -- ============================================================
  --  EtherType / Protocol constants
  -- ============================================================
  CONSTANT ETHERTYPE_IPV4 : word16_t := x"0800";
  CONSTANT ETHERTYPE_ARP : word16_t := x"0806";
  CONSTANT ETHERTYPE_IPV6 : word16_t := x"86DD";
  CONSTANT ETHERTYPE_VLAN : word16_t := x"8100";

  CONSTANT IP_PROTO_ICMP : byte_t := x"01";
  CONSTANT IP_PROTO_TCP : byte_t := x"06";
  CONSTANT IP_PROTO_UDP : byte_t := x"11";

  -- ============================================================
  --  Ethernet II Header  (14 bytes, no VLAN tag)
  --
  --   Offset  Size  Field
  --   ------  ----  ------------------------------------------
  --    0      6 B   Destination MAC address
  --    6      6 B   Source MAC address
  --   12      2 B   EtherType
  -- ============================================================
  TYPE eth_header_t IS RECORD
    dst_mac : mac_addr_t; -- Destination MAC (48 bits)
    src_mac : mac_addr_t; -- Source MAC      (48 bits)
    ethertype : word16_t; -- EtherType / length field
  END RECORD eth_header_t;

  CONSTANT ETH_HEADER_BITS : NATURAL := 112; -- 14 bytes × 8

  -- Reset / null value
  CONSTANT ETH_HEADER_RESET : eth_header_t := (
    dst_mac => (OTHERS => '0'),
    src_mac => (OTHERS => '0'),
    ethertype => ETHERTYPE_IPV4
  );

  -- ============================================================
  --  IPv4 Header  (20 bytes, no options)
  --
  --   Offset  Size  Field
  --   ------  ----  ------------------------------------------
  --    0      4 b   Version  (= 4)
  --    0+4    4 b   IHL ? Internet Header Length (in 32-bit words)
  --    1      1 B   DSCP (6 b) + ECN (2 b)
  --    2      2 B   Total Length (header + payload, bytes)
  --    4      2 B   Identification
  --    6      3 b   Flags  (bit2=DF, bit1=MF, bit0=reserved)
  --    6+3   13 b   Fragment Offset
  --    8      1 B   Time To Live
  --    9      1 B   Protocol
  --   10      2 B   Header Checksum
  --   12      4 B   Source IP address
  --   16      4 B   Destination IP address
  -- ============================================================
  TYPE ip_header_t IS RECORD
    version : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Should be "0100"
    ihl : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Header length (×4 bytes)
    dscp : STD_LOGIC_VECTOR(5 DOWNTO 0); -- Diff. Services Code Point
    ecn : STD_LOGIC_VECTOR(1 DOWNTO 0); -- Explicit Congestion Notif.
    total_length : word16_t; -- Total packet length (bytes)
    identification : word16_t; -- Fragment identification
    flags : STD_LOGIC_VECTOR(2 DOWNTO 0); -- bit2=DF, bit1=MF
    frag_offset : STD_LOGIC_VECTOR(12 DOWNTO 0); -- Fragment offset (×8 bytes)
    ttl : byte_t; -- Time To Live
    protocol : byte_t; -- Encapsulated protocol
    checksum : word16_t; -- Header checksum (ones' comp)
    src_ip : ipv4_addr_t; -- Source IPv4 address
    dst_ip : ipv4_addr_t; -- Destination IPv4 address
  END RECORD ip_header_t;

  CONSTANT IP_HEADER_BITS : NATURAL := 160; -- 20 bytes × 8 (no options)

  -- Reset / null value  (version=4, ihl=5 ? standard 20-byte header)
  CONSTANT IP_HEADER_RESET : ip_header_t := (
    version => x"4",
    ihl => x"5",
    dscp => (OTHERS => '0'),
    ecn => (OTHERS => '0'),
    total_length => (OTHERS => '0'),
    identification => (OTHERS => '0'),
    flags => "010", -- DF=1, MF=0 (don't fragment)
    frag_offset => (OTHERS => '0'),
    ttl => x"40", -- 64 hops
    protocol => IP_PROTO_UDP,
    checksum => (OTHERS => '0'),
    src_ip => (OTHERS => '0'),
    dst_ip => (OTHERS => '0')
  );

  -- ============================================================
  --  UDP Header  (8 bytes)
  --
  --   Offset  Size  Field
  --   ------  ----  ------------------------------------------
  --    0      2 B   Source port
  --    2      2 B   Destination port
  --    4      2 B   Length (header + data, bytes; min = 8)
  --    6      2 B   Checksum (optional in IPv4, mandatory in IPv6)
  -- ============================================================
  TYPE udp_header_t IS RECORD
    src_port : word16_t; -- Source UDP port
    dst_port : word16_t; -- Destination UDP port
    length : word16_t; -- UDP length (>= 8)
    checksum : word16_t; -- Checksum (0x0000 = disabled)
  END RECORD udp_header_t;

  CONSTANT UDP_HEADER_BITS : NATURAL := 64; -- 8 bytes × 8

  -- Reset / null value
  CONSTANT UDP_HEADER_RESET : udp_header_t := (
    src_port => (OTHERS => '0'),
    dst_port => (OTHERS => '0'),
    length => x"0008", -- minimum legal value (header only)
    checksum => (OTHERS => '0')
  );

  -- ============================================================
  --  Convenience: full frame header (Eth + IP + UDP, no options)
  --  Total: 14 + 20 + 8 = 42 bytes = 336 bits
  -- ============================================================
  TYPE eth_ip_udp_header_t IS RECORD
    eth : eth_header_t;
    ip : ip_header_t;
    udp : udp_header_t;
  END RECORD eth_ip_udp_header_t;

  CONSTANT ETH_IP_UDP_HEADER_BITS : NATURAL :=
  ETH_HEADER_BITS + IP_HEADER_BITS + UDP_HEADER_BITS; -- 336

  CONSTANT ETH_IP_UDP_HEADER_RESET : eth_ip_udp_header_t := (
    eth => ETH_HEADER_RESET,
    ip => IP_HEADER_RESET,
    udp => UDP_HEADER_RESET
  );

  -- ============================================================
  --  Helper functions
  -- ============================================================

  FUNCTION to_slv (hdr : eth_header_t) RETURN STD_LOGIC_VECTOR;
  FUNCTION to_slv (hdr : ip_header_t) RETURN STD_LOGIC_VECTOR;
  FUNCTION to_slv (hdr : udp_header_t) RETURN STD_LOGIC_VECTOR;

  FUNCTION to_eth_header (slv : STD_LOGIC_VECTOR(ETH_HEADER_BITS - 1 DOWNTO 0)
  ) RETURN eth_header_t;

  FUNCTION to_ip_header (slv : STD_LOGIC_VECTOR(IP_HEADER_BITS - 1 DOWNTO 0)
  ) RETURN ip_header_t;

  FUNCTION to_udp_header (slv : STD_LOGIC_VECTOR(UDP_HEADER_BITS - 1 DOWNTO 0)
  ) RETURN udp_header_t;

END PACKAGE header_pkg;

-- ============================================================
--  Package body ? function implementations
-- ============================================================
PACKAGE BODY header_pkg IS
  FUNCTION to_slv (hdr : eth_header_t) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v : STD_LOGIC_VECTOR(ETH_HEADER_BITS - 1 DOWNTO 0);
  BEGIN
    v(111 DOWNTO 64) := hdr.dst_mac;
    v(63 DOWNTO 16) := hdr.src_mac;
    v(15 DOWNTO 0) := hdr.ethertype;
    RETURN v;
  END FUNCTION;

  FUNCTION to_slv (hdr : ip_header_t) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v : STD_LOGIC_VECTOR(IP_HEADER_BITS - 1 DOWNTO 0);
  BEGIN
    v(159 DOWNTO 156) := hdr.version;
    v(155 DOWNTO 152) := hdr.ihl;
    v(151 DOWNTO 146) := hdr.dscp;
    v(145 DOWNTO 144) := hdr.ecn;
    v(143 DOWNTO 128) := hdr.total_length;
    v(127 DOWNTO 112) := hdr.identification;
    v(111 DOWNTO 109) := hdr.flags;
    v(108 DOWNTO 96) := hdr.frag_offset;
    v(95 DOWNTO 88) := hdr.ttl;
    v(87 DOWNTO 80) := hdr.protocol;
    v(79 DOWNTO 64) := hdr.checksum;
    v(63 DOWNTO 32) := hdr.src_ip;
    v(31 DOWNTO 0) := hdr.dst_ip;
    RETURN v;
  END FUNCTION;

  FUNCTION to_slv (hdr : udp_header_t) RETURN STD_LOGIC_VECTOR IS
    VARIABLE v : STD_LOGIC_VECTOR(UDP_HEADER_BITS - 1 DOWNTO 0);
  BEGIN
    v(63 DOWNTO 48) := hdr.src_port;
    v(47 DOWNTO 32) := hdr.dst_port;
    v(31 DOWNTO 16) := hdr.length;
    v(15 DOWNTO 0) := hdr.checksum;
    RETURN v;
  END FUNCTION;

  FUNCTION to_eth_header (slv : STD_LOGIC_VECTOR(ETH_HEADER_BITS - 1 DOWNTO 0))
    RETURN eth_header_t
    IS
    VARIABLE hdr : eth_header_t;
  BEGIN
    hdr.dst_mac := slv(111 DOWNTO 64);
    hdr.src_mac := slv(63 DOWNTO 16);
    hdr.ethertype := slv(15 DOWNTO 0);
    RETURN hdr;
  END FUNCTION;

  FUNCTION to_ip_header (slv : STD_LOGIC_VECTOR(IP_HEADER_BITS - 1 DOWNTO 0))
    RETURN ip_header_t
    IS
    VARIABLE hdr : ip_header_t;
  BEGIN
    hdr.version := slv(159 DOWNTO 156);
    hdr.ihl := slv(155 DOWNTO 152);
    hdr.dscp := slv(151 DOWNTO 146);
    hdr.ecn := slv(145 DOWNTO 144);
    hdr.total_length := slv(143 DOWNTO 128);
    hdr.identification := slv(127 DOWNTO 112);
    hdr.flags := slv(111 DOWNTO 109);
    hdr.frag_offset := slv(108 DOWNTO 96);
    hdr.ttl := slv(95 DOWNTO 88);
    hdr.protocol := slv(87 DOWNTO 80);
    hdr.checksum := slv(79 DOWNTO 64);
    hdr.src_ip := slv(63 DOWNTO 32);
    hdr.dst_ip := slv(31 DOWNTO 0);
    RETURN hdr;
  END FUNCTION;

  FUNCTION to_udp_header (slv : STD_LOGIC_VECTOR(UDP_HEADER_BITS - 1 DOWNTO 0))
    RETURN udp_header_t
    IS
    VARIABLE hdr : udp_header_t;
  BEGIN
    hdr.src_port := slv(63 DOWNTO 48);
    hdr.dst_port := slv(47 DOWNTO 32);
    hdr.length := slv(31 DOWNTO 16);
    hdr.checksum := slv(15 DOWNTO 0);
    RETURN hdr;
  END FUNCTION;

END PACKAGE BODY header_pkg;