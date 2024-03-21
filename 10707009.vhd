----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Manuel Tacca
-- 
-- Create Date: 01/05/2023 09:43:08 AM
-- Design Name: Prova Finale (Progetto di Reti Logiche)
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: project_reti_logiche
-- Tool Versions: 2016.4
--
-- Description: 
-- La specifica della “Prova Finale (Progetto di Reti Logiche)” per l’Anno Accademico
-- 2022/2023 chiede di implementare un modulo HW (descritto in VHDL) che si interfacci con
-- una memoria e che rispetti le indicazioni riportate nella seguente specifica.
-- Ad elevato livello di astrazione, il sistema riceve indicazioni circa una locazione di memoria,
-- il cui contenuto deve essere indirizzato verso un canale di uscita fra i quattro disponibili.
-- Le indicazioni circa il canale da utilizzare e l’indirizzo di memoria a cui accedere vengono
-- forniti mediante un ingresso seriale da un bit, mentre le uscite del sistema, ovvero i succitati
-- canali, forniscono tutti i bit della parola di memoria in parallelo. 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    Port ( 
            i_clk       : in  STD_LOGIC;
            i_rst       : in  STD_LOGIC;
            i_start     : in  STD_LOGIC;
            i_w         : in  STD_LOGIC;
            
            o_z0        : out STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z1        : out STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z2        : out STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z3        : out STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_done      : out STD_LOGIC;
            
            o_mem_addr  : out STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_mem_data  : in  STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_mem_we    : out STD_LOGIC;
            o_mem_en    : out STD_LOGIC
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    
    type state_type is (IDLE, START, FIX_ADDR, MEM_LOOKUP, WAIT_DATA, READ_DATA, STABILIZE_DATA, WRITE_Z_REG, DONE, WAIT_START);
    
    signal state      : state_type := IDLE ;
    
    signal count_chnl : UNSIGNED(1 DOWNTO 0)          := "10";
    signal count_addr : UNSIGNED(4 DOWNTO 0)          := "00000";
    signal c_help     : INTEGER                       := 1;
    signal channel    : STD_LOGIC_VECTOR(1 DOWNTO 0)  := "00";
    signal mem_inv    : STD_LOGIC_VECTOR(15 DOWNTO 0) := "0000000000000000"; 
    signal mem_addr   : STD_LOGIC_VECTOR(15 DOWNTO 0) := "0000000000000000";
    signal data       : STD_LOGIC_VECTOR(7 DOWNTO 0)  := "00000000";
    signal z0_reg     : STD_LOGIC_VECTOR(7 DOWNTO 0)  := "00000000";
    signal z1_reg     : STD_LOGIC_VECTOR(7 DOWNTO 0)  := "00000000";
    signal z2_reg     : STD_LOGIC_VECTOR(7 DOWNTO 0)  := "00000000";
    signal z3_reg     : STD_LOGIC_VECTOR(7 DOWNTO 0)  := "00000000";

begin
    
    fsm_status: process( i_clk, i_rst ) begin
        if( rising_edge( i_clk ) ) then
            if ( i_rst = '1' ) then
                state <= IDLE;
                count_chnl <= "10";
                count_addr <= (others => '0');
                c_help <= 1;
                channel <= (others => '0');
                mem_addr <= (others => '0');
                mem_inv <= (others => '0' );
                data <= (others => '0');
                z0_reg <= (others => '0');
                z1_reg <= (others => '0');
                z2_reg <= (others => '0');
                z3_reg <= (others => '0');
                o_z0 <= (others => '0');
                o_z1 <= (others => '0');
                o_z2 <= (others => '0');
                o_z3 <= (others => '0');
            else
                case state is
                    when IDLE =>
                        if ( i_start = '1' ) then
                            channel( to_integer ( count_chnl ) - 1 ) <= i_w;
                            count_chnl <= "01";
                            state <= START;
                        else
                            state <= IDLE;
                        end if;
                    
                    when START =>
                        if ( i_start = '1' ) then
                            if ( count_chnl = "01" ) then
                                channel( 0 ) <= i_w;
                                count_chnl <= "00";
                            elsif ( count_chnl = "00" ) then
                                mem_inv( to_integer( count_addr ) ) <= i_w;
                                count_addr <= count_addr + "00001";
                            end if;
                            state <= START;
                        elsif ( i_start = '0' ) then
                            state <= FIX_ADDR;
                        end if;
                    when FIX_ADDR =>
                        if ( count_addr > "00000" ) then
                            if ( count_addr = "00001" ) then
                                mem_addr( 0 ) <= mem_inv( 0 );
                                o_mem_en <= '1';
                                state <= MEM_LOOKUP;
                            elsif ( count_addr > "00001" ) then
                                if ( to_integer( count_addr ) = c_help ) then
                                    mem_addr( c_help - 1 ) <= mem_inv( c_help - 1 );
                                    o_mem_en <= '1';
                                    state <= MEM_LOOKUP;
                                elsif ( to_integer( count_addr ) < c_help ) then
                                    o_mem_en <= '1';
                                    state <= MEM_LOOKUP;
                                else
                                    mem_addr( to_integer( count_addr ) - 1 ) <= mem_inv( c_help - 1 );
                                    mem_addr( c_help - 1 ) <= mem_inv( to_integer( count_addr ) - 1 );
                                    count_addr <= count_addr - "00001";
                                    c_help <= c_help + 1;   
                                end if;
                            end if;
                        else    
                            o_mem_en <= '1';
                            state <= MEM_LOOKUP;
                        end if;
                    when MEM_LOOKUP =>
                        o_mem_addr <= mem_addr;
                        state <= WAIT_DATA;
                    when WAIT_DATA =>
                        state <= READ_DATA;
                    when READ_DATA =>
                        data <= i_mem_data;
                        state <= STABILIZE_DATA;
                    when STABILIZE_DATA =>
                        o_mem_en <= '0';
                        o_mem_addr <= (others => '0');
                        state <= WRITE_Z_REG;
                    when WRITE_Z_REG =>
                        case channel is
                            when "00" =>
                                z0_reg <= data;
                            when "01" =>
                                z1_reg <= data;
                            when "10" =>
                                z2_reg <= data;
                            when "11" =>
                                z3_reg <= data;
                            when others =>
                                z0_reg <= (others => '0');
                                z1_reg <= (others => '0');
                                z2_reg <= (others => '0');
                                z3_reg <= (others => '0');
                        end case;
                        state <= DONE;
                    when DONE =>
                        o_done <= '1';
                        o_z0 <= z0_reg;
                        o_z1 <= z1_reg;
                        o_z2 <= z2_reg;
                        o_z3 <= z3_reg;
                        state <= WAIT_START;
                    when WAIT_START =>
                        if ( i_start = '0' ) then
                            state <= WAIT_START;
                            o_done <= '0';
                            channel <= (others => '0');
                            mem_addr <= (others => '0');
                            mem_inv <= (others => '0');
                            data <= (others => '0');
                            count_chnl <= "10";
                            count_addr <= (others => '0');
                            c_help <= 1;
                            o_z0 <= (others => '0');
                            o_z1 <= (others => '0');
                            o_z2 <= (others => '0');
                            o_z3 <= (others => '0');
                        else
                            channel( 1 ) <= i_w;
                            count_chnl <= "01";
                            state <= START;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_status;
    
end Behavioral;