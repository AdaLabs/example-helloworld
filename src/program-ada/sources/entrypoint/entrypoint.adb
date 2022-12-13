pragma SPARK_Mode;
pragma Restrictions (No_Secondary_Stack);
--  llvm-gcc -I/home/david/.local/share/solana/install/active_release/bin/sdk/bpf/ada/inc -c entrypoint.adb 
--

with Interfaces.C.Strings;
with Interfaces.C.Extensions; use Interfaces.C.Extensions;
with System.Memory;
with types_h; use types_h;
with Ada.Unchecked_Conversion;
--  
-- SDK.Solana
with log_h; use log_h;
with SDK.Loggers; use SDK.Loggers;
with entrypoint_h; use entrypoint_h;
with deserialize_h; use deserialize_h;
with pubkey_h; use pubkey_h;

function entrypoint (input : access uint8_t) return uint64_t
is
   type uint8_t_Access is access all uint8_t;
   type uint32_t_Access is access all uint32_t;
   function To_UL is new Ada.Unchecked_Conversion (System.Address,
                                                   Interfaces.C.unsigned_long);
   
   function To_Address is new Ada.Unchecked_Conversion (uint8_t_Access,
                                                        uint32_t_Access);
   function To_Address is new Ada.Unchecked_Conversion (uint8_t_Access,
                                                        System.Address);
   
   --  TODO
   --  Where is Ada.Unchecked_Conversion defined ?
   --
   account         : aliased SolAccountInfo;
   greeted_account : access  SolAccountInfo;
   params          : aliased SolParameters;
   Status          :         bool;
   num_greets      :         uint32_t_Access;
   use type Interfaces.C.unsigned_long,
       Interfaces.C.unsigned,
       Interfaces.C.C_Bool;
begin
   Log ("Hello Solana world from Ada !");
   
   params.ka := account'Unrestricted_Access;
   Status    := sol_deserialize (input  => input,
                                 params => params'Access,
                                 ka_num => 1);
   if Status then
      if params.ka_num < 1 then
         return ERROR_NOT_ENOUGH_ACCOUNT_KEYS;
      end if;
      greeted_account := params.ka;

      if not SolPubkey_same (greeted_account.owner, params.program_id) then
         sol_log_pubkey (params.program_id);
         return ERROR_INCORRECT_PROGRAM_ID;
      end if;
      Log ("(II) greeted_account.owner");
      sol_log_pubkey (greeted_account.owner);
      Log ("(II) program_id");
      sol_log_pubkey (params.program_id);
      
      if greeted_account.data_len = uint32_t'Size / 8 then
         Log ("(II)greeted_account.data_len = uint32_t'Size / 8");
         num_greets     := To_Address (uint8_t_Access (greeted_account.data));
         num_greets.all := num_greets.all + 2;
         declare
           Greetings : uint32_t;
           for Greetings'Address use To_Address (uint8_t_Access (greeted_account.data));
         begin
           Greetings := Greetings + 20;
           sol_log_64_u (16#42#, 16#42#, 16#42#, 16#42#, Interfaces.C.unsigned_long (Greetings));
         end;
      else
         Log ("(FF)bad greeted_account.data_len size");
         sol_log_64_u (0, 0, 0, 0, greeted_account.data_len);
         return ERROR_INVALID_ACCOUNT_DATA;
      end if;
      return SUCCESS;
   else
      return ERROR_INVALID_ARGUMENT;
   end if;
end entrypoint;
