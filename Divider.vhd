library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider is
    port (
        clk        : in std_logic;
        reset      : in std_logic;
        start      : in std_logic;
        dividend   : in std_logic_vector(31 downto 0);
        divisor    : in std_logic_vector(31 downto 0);
        quotient   : out std_logic_vector(31 downto 0);
        remainder  : out std_logic_vector(31 downto 0);
        done       : out std_logic;
		stop_flag  : out std_logic ---------------------new---------------------
    );
end entity Divider;

architecture Behavioral of Divider is
    type state_type is (idle, processing, mid, complete,sub);
    signal state          : state_type := idle;
    signal counter        : integer range 0 to 32 := 0;
    signal UpperTable    : std_logic_vector(63 downto 0);-- := (others => '0');
	signal Result			: std_logic_vector(31 downto 0) := (others => '0');
	signal QuotientTable   : std_logic_vector(31 downto 0) := (others => '0');
	signal CalcPosOrNeg		: STD_LOGIC := '0';

begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= idle;                      
            counter <= 0;
            UpperTable <= (others => '0');
            done <= '0';
            quotient <= (others => '0');
            remainder <= (others => '0');
			QuotientTable <= (others => '0');
			stop_flag <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    if start = '1' then
						
                        state <= processing;                    
                        UpperTable<= x"00000000" & dividend;
                        counter <= 32;
                        done <= '0';
                    end if;
                when processing =>
                      if counter > 0 then                           
                        UpperTable <= UpperTable(62 downto 0) & '0';
                        counter <= counter - 1;
						
                        state <= sub;
                     else
                        state <= complete;
						stop_flag <= '1';
                      end if;
				 when sub =>
						Result <= std_logic_vector(unsigned(UpperTable(63 downto 32)) - unsigned(divisor));
						state <= mid;
						
                 when mid =>								
                            if Result(31) ='1' then
								CalcPosOrNeg <= '0';
                                QuotientTable <= QuotientTable(30 downto 0) & '0';
                            elsif Result(31) = '0' then
								CalcPosOrNeg <= '1';
                                UpperTable(63 downto 32) <= Result;
								QuotientTable <= QuotientTable(30 downto 0) & '1';
                            end if;
                        state <= processing;                                     
                when complete =>
                    quotient <= QuotientTable;
                    remainder <= std_logic_vector(UpperTable(63 downto 32));
                    done <= '1';
                    state <= idle;
					stop_flag <= '0';					
            end case;
        end if;
    end process;

end architecture Behavioral;