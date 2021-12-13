-- Implement the banking data model 
-- Create first parent table
create table customer(
CUST_ID varchar2(11) not null,
FIRST_NAME varchar2(25) not null,
LAST_NAME varchar2(25) not null,
PASSWD varchar2(6) not null);
-- Add PK
alter table customer
add constraint customer_id_pk primary key(CUST_ID);

-- Create second parent table 
create table account_type(
ACCTY_ID number(6) not null,
ACCTY_NAME varchar2(20) not null,
PRESENT_INTEREST number(5,2) not null);
-- Add PK
alter table account_type
add constraint account_type_id_pk primary key(ACCTY_ID);

-- Create first child table 
create table interest_change(
INTCH_ID number(6) not null,
ACCTY_ID number(6) not null,
INTEREST number(5,2) not null,
DATE_TIME date default sysdate not null);
-- Add PK,FK
alter table interest_change
add constraint interest_id_pk primary key(INTCH_ID)
add constraint interest_accty_id_fk foreign key(ACCTY_ID) references account_type(ACCTY_ID);

-- Create second child table 
create table account(
ACC_ID number(8) not null,
ACCTY_ID number(6) not null,
DATE_TIME date default sysdate not null,
BALANCE number(10,2) not null);
-- ADD PK,FK
alter table account 
add constraint account_id_pk primary key(ACC_ID)
add constraint account_accty_id_fk foreign key(ACCTY_ID) references account_type(ACCTY_ID);

-- Create third child table 
create table account_owner(
ACCOW_ID number(9) not null,
CUST_ID varchar2(11) not null,
ACC_ID number(8) not null);    -- Note that all "acc_id" FK will have different constraint names but referens same PK in account table 
-- Add PK,FK
alter table account_owner
add constraint account_owner_id_pk primary key(ACCOW_ID)
add constraint account_owner_cust_id_fk foreign key(CUST_ID) references customer(CUST_ID)
add constraint account_owner_acc_id_fk foreign key(ACC_ID) references account(ACC_ID);

-- Create fourth child table 
create table withdrawal(
WIT_ID number(9) not null,
CUST_ID varchar2(11) not null,
ACC_ID number(8) not null,
AMOUNT number(10,2) not null,
DATE_TIME date default sysdate not null);
-- Add PK,FK 
alter table withdrawal
add constraint withdrawal_id_pk primary key(WIT_ID)
add constraint withdrawal_cust_id_fk foreign key(CUST_ID) references customer(CUST_ID)
add constraint withdrawal_acc_id_fk foreign key(ACC_ID) references account(ACC_ID);

-- Create fifth child table 
create table deposition(
DEP_ID number(9) not null,
CUST_ID varchar2(11) not null,
ACC_ID number(8) not null,
AMOUNT number(10,2) not null,
DATE_TIME date default sysdate not null);
-- ADD PK,FK
alter table deposition
add constraint deposition_id_pk primary key(DEP_ID)
add constraint deposition_cust_id foreign key(CUST_ID) references customer(CUST_ID)
add constraint deposition_acc_id foreign key(ACC_ID) references account(ACC_ID);

-- Create last child table 
create table transfer(
TRA_ID number(9) not null,
CUST_ID varchar2(11) not null,
FROM_ACC_ID number(8) not null,
TO_ACC_ID number(8) not null,
AMOUNT number(10,2) not null,
DATE_TIME date default sysdate not null);
-- Add PK,FK (dont forget to use "FROM_ACC_ID" and "TO_ACC_ID" in FK
alter table transfer
add constraint transfer_id_pk primary key(TRA_ID)
add constraint transfer_cust_id_fk foreign key(CUST_ID) references customer(CUST_ID)
add constraint transfer_from_acc_id_fk foreign key(FROM_ACC_ID) references account(ACC_ID)
add constraint transfer_to_acc_id_fk foreign key(TO_ACC_ID) references account(ACC_ID);


-- Create a trigger called biufer_customer that starts before insert or
-- update of the column passwd in the customer table. The trigger verifies 
-- that the password is exactly six characters long.

create or replace trigger biufer_customer
before insert or update  -- Use "before or update"
of PASSWD 
on customer
for each row   -- Apply to each row
begin 
 if length(:new.PASSWD) != 6 then  -- If new input is not length=6 return error
 raise_application_error(-20001, 'PASSWD must be of length 6');
 end if;
end;


-- Create a procedure called do_new_cutomer. The procedure is used
-- to add new rows to the customer table. 

create or replace procedure do_new_customer(
p_cust_id in varchar2,  -- State all parameters to use, (should match columns in original table)
p_fname in varchar2,    -- Cannot use varchar2(number)
p_ename in varchar2,
p_passwd in varchar2)
as  
begin    -- Then insert these parameters into each respective column 
 insert into customer(CUST_ID,FIRST_NAME,LAST_NAME,PASSWD) values(p_cust_id,p_fname,p_ename,p_passwd);
 commit;
end;


-- Create a sequence to use for primary key
-- values for the following tables:
--•	Transfer
--•	Deposition
--•	Withdrawal
--•	Account_owner
--•	Interest_change

create sequence pk_seq
start with 1
increment by 1


-- Create a function named log_in. This should return (zero) if the login
-- failed, or (one) if the login was successful. 

create or replace function log_in(
p_name in varchar2,   -- State parameters to use
p_pass in varchar2)
return varchar2       
as 
state number;         -- Create variable "state" to use in output
begin 
 select count(*)      -- Put 0 into state if inputs do not match or one if match
  into state 
   from customer
   where CUST_ID = p_name  -- Go through rows to see if name/passwd match
  and PASSWD = p_pass;
 if state = 0 then     -- If function counts 0, we return zero
 return state;
elsif state = 1 then   -- If functions counts 1, we return one
return state;
end if;
end;



-- Create a function called get_balance. This should return the current
-- balance for the account whose account number (acc_id) is sent to the function. 

create or replace function get_balance(
p_acc_id in number)  -- We only need to create 1 numerical parameter 
return number
as 
current_balance number(10,2);  -- Create new variable to store balance in
begin 
 select sum(BALANCE)  -- Select the sum of correct column 
  into current_balance  -- Put into variable
   from account   -- From correct table 
   where ACC_ID = p_acc_id;  -- Where input number equals a designated account number
  return current_balance;   -- Return its value
end;


-- Create a function called get_authority. This function takes two
-- parameters:  cust_id and acc_id, and returns
-- (one), if the customer has the right to make withdrawals from the account,
-- or (zero), if the customer doesn't have any authority to the account.

create or replace function get_authority(
p_CustID in varchar2,  -- Create parameters 
p_AccID in varchar2)
return number  -- Returns a number
as
access number;   -- Create variable to store (0,1) into
begin
 select count(*) -- Count if input equals the value in the designated row
 into access
  from account_owner  -- State table to work from
   where CUST_ID = p_CustID and ACC_ID = p_AccID;  -- Where both conditions must hold
    if access = 0 then
    return access;
   elsif access = 1 then
  return access;
 end if;
end;


-- Create a trigger called aifer_deposition. The trigger ensures
-- that the balance is right after deposition to an account. 

create or replace trigger aifer_deposition
after insert
on deposition   -- Use table "deposition"
 for each row
begin
 update account  -- Make sure correct balance after a deposition using "update"
  set BALANCE = BALANCE + :new.AMOUNT  -- Update balance in "account" with old balance + new deposit
 where ACC_ID = :new.ACC_ID;  -- Where PKs row is updated with new amount
end;


-- Create a trigger called bifer_withdrawal. The trigger ensures
-- that you cannot withdraw more money than there is available in the
-- account.

create or replace trigger bifer_withdrawal
before insert 
on withdrawal   -- Use table withdrawal
 for each row

begin 
-- Here we use, if current balance is smaller than the widrawal we raise and error.
-- Note here that we MUST use the account id in the function "get_balance" to work.
  if get_balance(:new.ACC_ID) < :new.AMOUNT then  
   raise_application_error(-20001,'Insufficient funds');
  end if;
end;


-- Create a trigger called aifer_withdrawal. The trigger ensures
-- that the balance is correct after withdrawal on an account.

create or replace trigger aifer_withdrawal
after insert on withdrawal
 for each row
begin
  if get_balance(:new.ACC_ID) < :new.AMOUNT then
    raise_application_error(-20001, 'Not correct balance');
  else
    update account
    set BALANCE = BALANCE - :new.AMOUNT
    where ACC_ID  = :new.ACC_ID;
  end if;
end;


-- Create an additional trigger.
-- The trigger ensures that you cannot take out more money than there is available
-- in the account that you are moving money from, when you transfer money from one
-- account to another. 

create or replace trigger bifer_transfer
before insert
on transfer  -- Now use table "transfer"
 for each row
 
begin 
-- If the balance in a specific row in column "from_acc_id" is less than the amount
-- we want to transfer to "to_acc_id" then we raise error. NOTE that the "AMOUNT"
-- in this trigger is specified by table "transfer" eventhough all three (action tables)
-- have the same column name.
 if get_balance(:new.FROM_ACC_ID) < :new.AMOUNT then 
  raise_application_error(-20001, 'Not correct balance');
 end if;
end;


-- This trigger ensures that the balance is correct on the accounts
-- after the transaction is completed. 

create or replace trigger aifer_transfer
after insert 
on transfer   -- Still use "transfer" table
 for each row

begin 
 update account  -- We can use "update" to ensure that transactions and balances agrees
  set BALANCE = BALANCE - :new.AMOUNT  -- Update current balance to balance minus amount taken out
   where ACC_ID = :new.FROM_ACC_ID;  -- Where current balance form new balance after taken out
 update account
  set BALANCE = BALANCE + :new.AMOUNT  -- Update current balance with amount taken out is being put in again
   where ACC_ID = :new.TO_ACC_ID;  -- Where current balance form new balance after putting in
end;
-- When it is a transfer between own accounts, total balance should not change


-- Create a procedure called do_deposition. The procedure creates a row
-- in the table deposition. After the transaction has committed, a message 
-- containing the balance of the account after the deposit is printed out.
create or replace procedure do_deposition(
p_dep_id in varchar2,
p_cust_id in varchar2,  -- State all parameters to use 
p_acc_id in varchar2,
p_amount in number,
p_date_time in date)
as 
begin -- Insert input into tale "deposition"
 insert into deposition(DEP_ID,CUST_ID,ACC_ID,AMOUNT,DATE_TIME) values(p_dep_id,p_cust_id,p_acc_id,p_amount,p_date_time);
  commit; -- Commit and print using get_balance before deposit + amount putted in
  dbms_output.put_line('The current balance is '|| get_balance(p_acc_id));
end;


-- Create a procedure called do_withdrawal. The procedure creates a row
-- in the table withdrawal and raises error when the customer doesn't
-- have any authority to the account.

create or replace procedure do_withdrawal(
p_wit_id in varchar2,
p_cust_id in varchar2,  -- State all parameters to use
p_acc_id in varchar2,
p_amount in number,
p_date_time in date)
as begin
 if get_authority(p_cust_id,p_acc_id) = 0 then  -- Use the fact that function returns [0 or 1] to determine outcome
  dbms_output.put_line('Unauthorized user!');  -- We dont not actually have to stop transaction, we only need to not follow through
   elsif get_authority(p_cust_id,p_acc_id) = 1 then  -- If authority granted, follow through with "insert into"
    insert into withdrawal(WIT_ID,CUST_ID,ACC_ID,AMOUNT,DATE_TIME) values(p_wit_id,p_cust_id,p_acc_id,p_amount,p_date_time);
   commit;
  dbms_output.put_line('The current balance is '|| get_balance(p_acc_id));  
 end if;
end;



-- Create a procedure called do_transfer. The procedure creates a row in
-- the table transfer and raises error when the customer doesn't have any authority
-- to the account from which money is withdrawn.

create or replace procedure do_transfer(
p_tra_id in number,
p_cust_id in varchar2,  -- State all parameters to use, re-use much of code for previous task
p_from_acc_id in number,
p_to_acc_id in number,
p_amount in number,
p_date_time in date)
as begin
-- Note, we only use "from" account to verify access since "to" account can be anyones account and must not match in cust_id
 if get_authority(p_cust_id, p_from_acc_id) = 0  then  
  dbms_output.put_line('Unauthorized user!');  
   elsif get_authority(p_cust_id, p_from_acc_id) = 1 then  -- If authorized, insert values, which will update accoun table after
    insert into transfer(TRA_ID, CUST_ID, FROM_ACC_ID, TO_ACC_ID, AMOUNT, DATE_TIME) values(p_tra_id, p_cust_id, p_from_acc_id, p_to_acc_id, p_amount, p_date_time);
   commit;
  dbms_output.put_line('The current balance of FROM_ACC_ID is: '|| get_balance(p_from_acc_id)||' And current balance of TO_ACC_ID is: '|| get_balance(p_to_acc_id));  
 end if;
end;

*.sql linguist-language=SQL
