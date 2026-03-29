LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE axi4l_bus IS
  TYPE t_ar IS RECORD
    araddr : STD_LOGIC_VECTOR;
    arvalid : STD_LOGIC;
    arready : STD_LOGIC;
  END RECORD;

  TYPE t_r IS RECORD
    rdata : STD_LOGIC_VECTOR;
    rvalid : STD_LOGIC;
    rready : STD_LOGIC;
  END RECORD;

  TYPE t_aw IS RECORD
    awaddr : STD_LOGIC_VECTOR;
    awvalid : STD_LOGIC;
    awready : STD_LOGIC;
  END RECORD;

  TYPE t_w IS RECORD
    wdata : STD_LOGIC_VECTOR;
    wvalid : STD_LOGIC;
    wready : STD_LOGIC;
  END RECORD;

  TYPE t_b IS RECORD
    bresp : STD_LOGIC_VECTOR(1 DOWNTO 0);
    bvalid : STD_LOGIC;
    bready : STD_LOGIC;
  END RECORD;

  TYPE t_axi4l_bus IS RECORD
    ar : t_ar;
    r : t_r;
    aw : t_ar;
    w : t_w;
    b : t_b;
  END RECORD;
END PACKAGE;