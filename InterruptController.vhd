LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

entity InterruptController is
    port(   clock					: IN 	STD_LOGIC; 
            address                 : IN    STD_LOGIC_VECTOR( 6 DOWNTO 0 ); -- a11, a5 downto a0
            DataBus		 	        : INOUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
            MemRead	 		        : IN 	STD_LOGIC;
			MemWrite	 	        : IN 	STD_LOGIC;
            irq                     : IN 	STD_LOGIC_VECTOR(6 DOWNTO 0);
            rstBtn			        : IN 	STD_LOGIC;
            GIE	 			        : IN 	STD_LOGIC;
			  INTA	 		        : IN 	STD_LOGIC;
            INTR_out		 	    : OUT 	STD_LOGIC;
            reset_out  	 	        : OUT 	STD_LOGIC;
            PC_ENABLE               : IN    STD_LOGIC
        );
end InterruptController;

ARCHITECTURE behavior OF InterruptController IS
    component BidirPin IS
        GENERIC( WIDTH: INTEGER:=16 );
        PORT(   Dout: 	IN 		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                en:		IN 		STD_LOGIC;
                Din:	OUT		STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                IOpin: 	INOUT 	STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)
        );
    END component;

    SIGNAL CS			 	    	            : STD_LOGIC_VECTOR( 2 DOWNTO 0 );
    SIGNAL Dout_IE, Dout_IFG, Dout_TYPE  	    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL Din_IE, Din_IFG, Din_TYPE		    : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
    SIGNAL EN_IE_W, EN_IFG_W              		: STD_LOGIC;
    SIGNAL EN_IE_R, EN_IFG_R, EN_TYPE_R			: STD_LOGIC;
    SIGNAL IE_reg, IFG_reg, TYPE_reg  		   	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL IFG_reg_in, TYPE_reg_in     		   	: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
    SIGNAL reset_counter                        : STD_LOGIC_VECTOR(1 DOWNTO 0 );
    SIGNAL reset,INTR_reset                     : STD_LOGIC;
    SIGNAL irq_rising, irq_clr                  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL INTR, prev_rstBtn                                 : STD_LOGIC;

    
begin 

    BiDirPin_IE: BidirPin
        GENERIC MAP ( 32 )
        PORT MAP (	Dout 		=> Dout_IE,
                    en			=> EN_IE_R,
                    Din			=> Din_IE,
                    IOpin 		=> DataBUS );


    BiDirPin_IFG: BidirPin
        GENERIC MAP ( 32 )
        PORT MAP (	Dout 		=> Dout_IFG,
                    en			=> EN_IFG_R,
                    Din			=> Din_IFG,
                    IOpin 		=> DataBUS );  
                    
    BiDirPin_TYPE: BidirPin
        GENERIC MAP ( 32 )
        PORT MAP (	Dout 		=> Dout_TYPE,
                    en			=> EN_TYPE_R,
                    Din		    => Din_TYPE,
                    IOpin 		=> DataBUS );             


    
    WITH address SELECT
    CS <=   "001" WHEN "1111100", --0x83C-- IE
            "010" WHEN "1111101", --0x83D IFG
            "100" WHEN "1111110", --0x83E TYPE
            "000" WHEN OTHERS;

    Dout_IE <= X"000000" & IE_reg; 
    Dout_IFG <= X"000000" & IFG_reg;
    Dout_TYPE <= X"000000" & TYPE_reg;

    EN_IE_W <= '1' WHEN CS(0) = '1' AND MemWrite = '1' ELSE '0';
    EN_IFG_W <= '1' WHEN CS(1) = '1' AND MemWrite = '1' ELSE '0'; 
    

    EN_IE_R <= '1' WHEN CS(0) = '1' AND MemRead = '1' ELSE '0';
    EN_IFG_R <= '1' WHEN CS(1) = '1' AND MemRead = '1' ELSE '0';
    EN_TYPE_R <= '1' WHEN INTA = '0' OR (CS(2) = '1' AND MemRead = '1') ELSE '0';

	irq_clr(0) <= '1' WHEN ((TYPE_reg = X"04" OR TYPE_reg = X"08") AND INTA = '0') ELSE '0';
	irq_clr(1) <= '1' WHEN (TYPE_reg = X"0C" AND INTA = '0') ELSE '0';
	irq_clr(2) <= '1' WHEN (TYPE_reg = X"10" AND INTA = '0') ELSE '0';
	irq_clr(3) <= '1' WHEN (EN_IFG_W = '1' AND Din_IFG(3) = '0') ELSE '0';
	irq_clr(4) <= '1' WHEN (EN_IFG_W = '1' AND Din_IFG(4) = '0') ELSE '0';
	irq_clr(5) <= '1' WHEN (EN_IFG_W = '1' AND Din_IFG(5) = '0') ELSE '0';
	irq_clr(6) <= '1' WHEN (TYPE_reg = X"20" AND INTA = '0') ELSE '0';


    IFG_reg_in <= ('0' & irq_rising) AND IE_reg;

    INTR_reset <= '1' WHEN reset_counter = "01" ELSE '0';
    INTR <= (((IFG_reg(0) OR IFG_reg(1) OR IFG_reg(2) OR IFG_reg(3) OR IFG_reg(4) OR IFG_reg(5) OR IFG_reg(6)) AND GIE) OR INTR_reset) AND PC_ENABLE;
	INTR_out <= INTR;

	TYPE_reg_in <=  X"00" WHEN reset = '1' ELSE
				    X"08" WHEN IFG_reg(0) = '1' ELSE 
					X"0C" WHEN IFG_reg(1) = '1' ELSE 
					X"10" WHEN IFG_reg(2) = '1' ELSE 
					X"14" WHEN IFG_reg(3) = '1' ELSE 
				    X"18" WHEN IFG_reg(4) = '1' ELSE 
					X"1C" WHEN IFG_reg(5) = '1' ELSE 
					X"20" WHEN IFG_reg(6) = '1' ELSE
					X"00";
    
    PROCESS(reset, irq(0), irq_clr(0)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(0) <= '0';
        ELSIF irq_clr(0) = '1' THEN
            irq_rising(0) <= '0';
        ELSIF (( irq(0)'EVENT ) AND ( irq(0) = '1')) THEN
            irq_rising(0) <= '1';
        END IF;
    END PROCESS;

    PROCESS(reset, irq(1), irq_clr(1)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(1) <= '0';
        ELSIF irq_clr(1) = '1' THEN
            irq_rising(1) <= '0';
        ELSIF (( irq(1)'EVENT ) AND ( irq(1) = '1')) THEN
            irq_rising(1) <= '1';
        END IF;
    END PROCESS;

    PROCESS(reset, irq(2), irq_clr(2)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(2) <= '0';
        ELSIF irq_clr(2) = '1' THEN
            irq_rising(2) <= '0';
        ELSIF (( irq(2)'EVENT ) AND ( irq(2) = '1')) THEN
            irq_rising(2) <= '1';
        END IF;
    END PROCESS;

    PROCESS(reset, irq(3), irq_clr(3)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(3) <= '0';
        ELSIF irq_clr(3) = '1' THEN
            irq_rising(3) <= '0';
        ELSIF (( irq(3)'EVENT ) AND ( irq(3) = '1')) THEN
            irq_rising(3) <= '1';
        END IF;
    END PROCESS;

    PROCESS(reset, irq(4), irq_clr(4)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(4) <= '0';
        ELSIF irq_clr(4) = '1' THEN
            irq_rising(4) <= '0';
        ELSIF (( irq(4)'EVENT ) AND ( irq(4) = '1')) THEN
            irq_rising(4) <= '1';
        END IF;
    END PROCESS;

    PROCESS(reset, irq(5), irq_clr(5)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(5) <= '0';
        ELSIF irq_clr(5) = '1' THEN
            irq_rising(5) <= '0';
        ELSIF (( irq(5)'EVENT ) AND ( irq(5) = '1')) THEN
            irq_rising(5) <= '1';
        END IF;
    END PROCESS;
	 
	 PROCESS(reset, irq(6), irq_clr(6)) 
    BEGIN
        IF reset = '1' THEN
            irq_rising(6) <= '0';
        ELSIF irq_clr(6) = '1' THEN
            irq_rising(6) <= '0';
        ELSIF (( irq(6)'EVENT ) AND ( irq(6) = '1')) THEN
            irq_rising(6) <= '1';
        END IF;
    END PROCESS;

    process(reset, clock, EN_IE_W) 
	begin
		if (reset = '1') then
			IE_reg <= X"FF";
		elsif (clock'EVENT) AND (clock = '1') then -- to check
			if (EN_IE_W = '1') then
				IE_reg <= Din_IE(7 downto 0);
			end if;
		end if;
	end process;

    process(reset, clock, EN_IFG_W) 
	begin
		if (reset = '1') then
			IFG_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then ----- to check
			if (EN_IFG_W = '1') then
				IFG_reg <= Din_IFG(7 downto 0);
            else 
                IFG_reg <= IFG_reg_in;
			end if;
		end if;
	end process;

    process(reset, clock)
	begin
		if (reset = '1') then
			TYPE_reg <= X"00";
		elsif (clock'EVENT) AND (clock = '1') then
            TYPE_reg <= TYPE_reg_in(7 downto 0);
		end if;
	end process;
	
	process(reset, clock,INTR)
	begin 
		if (clock'EVENT) AND (clock = '1') then
			prev_rstBtn <= rstBtn;
		END IF;
	END PROCESS;

    process(clock)
    begin 
        --IF (( rstBtn'EVENT ) AND ( rstBtn = '1')) THEN
        --    reset_counter <= "11";
        if (clock'EVENT) AND (clock = '1') then
				IF(prev_rstBtn = '1' AND rstBtn = '0') then
					reset_counter <= "11";
            ELSIF (reset_counter /= "00") THEN
                reset_counter <= reset_counter - 1;
            END IF;
        END IF;
    END PROCESS;

    -- process(reset, clock, reset_counter)
	-- begin
	-- 	if (clock'EVENT) AND (clock = '1') then
    --         IF (reset_counter =  "11" OR reset_counter =  "10") THEN
    --             reset <= '1';
    --         ELSE
    --             reset <= '0';
    --         END IF;
	-- 	end if;
	-- end process;

    reset <= '1' WHEN (reset_counter =  "11" OR reset_counter =  "10") ELSE '0';
    reset_out <= reset;    

END behavior;