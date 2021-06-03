use SurveyBrosAPITables;

drop table if exists Survey_Question_Answer_Type_Association;
drop table if exists Survey_Question_Answer_Type;
drop table if exists Survey_Question;

drop table if exists Survey_Response_Location_Copy;
drop table if exists Survey_Ownership_Copy;
drop table if exists Survey_Copy;

drop table if exists Survey_Response_Location;
drop table if exists Survey_Ownership;
drop table if exists Survey;

drop table if exists Active_Member_Subscription;
drop table if exists Active_Group_Subscription;
drop table if exists Active_Subscription;

drop table if exists Subscription_Tool_Associations;

drop table if exists Subscription_Type;
drop table if exists Subscription;

drop table if exists Tool;

drop table if exists Control_Globals;

drop table if exists Account_Lockdown;
drop table if exists Account_Group_Membership;
drop table if exists Account;
drop table if exists Group_Account;

create table if not exists Control_Globals (
                                               k varchar(64) unique not null,
                                               v varchar(64) unique not null
);

insert into Control_Globals (k, v) values
('accountLockdownFunctionEnabled', 'true');

/**
  Used to identify Groups - Institutions, etc ...
 */
create table if not exists Group_Account (
                                             ID integer primary key not null auto_increment,

    /**
      Company / Org / Institution Name
     */
                                             group_name varchar(256) unique not null,
                                             pass varchar(256) not null,

                                             date_created datetime not null default now()
);

create table if not exists Account (
                                       ID integer primary key not null auto_increment,

                                       email varchar(128) unique not null, # self explainatory
                                       pass  varchar(256) not null,        # same

                                       first_name varchar(128) default null,            # as
                                       last_name  varchar(64) default null,             # above

                                       date_created datetime default now() not null,   # auto handled
                                       date_modified datetime default now() not null,  # auto handled

                                       last_sign_in datetime,                              # optional, remembers last sign in, might be automatic

                                       email_confirmed boolean not null default false,     # self explainatory

                                       password_change_requested boolean not null default false, # if user requested pass reset OUTSIDE the account, flag should be turned on
                                       password_change_request_date datetime default null,       # if user requested pass reset OUTSIDE account, save time. Resets should be invalidated after a while

                                       is_locked_out boolean not null default false,             # set to True by Account_Lockdown_Log_Invalid_Auth, invalidate through Account_Lockdown_Try_Remove
                                       lockdown_start datetime default null                      # set to date by Account_Lockdown_Log_Invalid_Auth, invalidate through Account_Lockdown_Try_Remove
);

/**
  Users belonging to groups are multivaluated dependencies ( an user can be in none or more orgs., an org can have none or more members )
 */
create table if not exists Account_Group_Membership (
                                                        ID integer primary key not null auto_increment,

                                                        account_ID integer not null,
                                                        group_ID integer not null,

                                                        constraint unique Account_Unique_In_Group (account_ID, group_ID), # one member can exist in multiple orgs, but same member cannot be a part of the same org twice

                                                        constraint foreign key Account_Valid (account_ID) references Account(ID) on delete cascade, # account is deleted, invalidate
                                                        constraint foreign key Account_Group_Valid (group_ID) references Group_Account (ID) on delete cascade, # group deleted, invalidate

                                                        date_created datetime default now() not null, # date of member joining group

                                                        is_group_manager boolean default false not null # can manage members - rights are : GroupAccount > Account that is manager > Account that is not manager
);

create trigger if not exists Account_Modification_Update before update on Account for each row set new.date_modified = now(); # modification updates last modified

create table if not exists Account_Lockdown (
                                                ID integer primary key not null auto_increment,

                                                account_ID integer unique not null,

                                                last_attempt_date datetime default now() not null, # last incorrect password input
                                                attempt_count integer not null default 0, # attempts thus far since reset

                                                constraint foreign key Lockdown_Account_Valid (account_ID) references Account (ID) on delete cascade
);

# procedure for logging an invalid authentication on given account ID

create or replace procedure Account_Lockdown_Log_Invalid_Auth (in target_account_ID integer) modifies sql data
procedure_label:
begin
    declare functionality_check varchar(64);
    declare lockdown_ID integer;
    declare current_lock_counter integer;
    declare last_attempt datetime;

    # check if lockdown feature is enabled
    select v into functionality_check from Control_Globals where k = 'accountLockdownFunctionEnabled';

    if functionality_check != 'true' then
        # if not, return
        leave procedure_label;
    end if;

    # check account existence
    select ID into target_account_ID from Account where ID = target_account_ID;

    if target_account_ID = -1 then
        # if account ID invalid, throw
        signal sqlstate '45000' set message_text = 'User ID Invalid';
    end if;

    set lockdown_ID = -1;

    # find if lockdown log exists, request ID, counts thus far, last fail date
    select ID, attempt_count, last_attempt_date into lockdown_ID, current_lock_counter, last_attempt from Account_Lockdown where Account_Lockdown.account_ID = target_account_ID;

    # no previous attempts in the last 45 mins
    if lockdown_ID = -1 then
        insert into Account_Lockdown (account_ID) values (target_account_ID); # save a lockdown session
        leave procedure_label;
    end if;

    if timestampdiff(minute, last_attempt, now()) >= 45 then # previous session invalidated
        update Account_Lockdown set attempt_count = 0, last_attempt_date  = now() where ID = lockdown_ID;   # reset count and date
        update Account set is_locked_out = false where ID = target_account_ID;                              # reset lockdown
        leave procedure_label;
    end if;

    if current_lock_counter >= 3 then # too many attempts
        update Account set is_locked_out = true, lockdown_start = now() where ID = target_account_ID; # set locked out
        delete from Account_Lockdown where ID = lockdown_ID;                                          # remove lock attempt
        leave procedure_label;
    end if;

    update Account_Lockdown set attempt_count = current_lock_counter + 1, last_attempt_date = now() where ID = lockdown_ID; # save attempt count incremented
end;

create or replace procedure Account_Lockdown_Try_Remove(in target_account_ID integer)
procedure_label:
begin
    declare functionality_check varchar(64);
    declare lock_date datetime;
    declare is_locked boolean;

    select v into functionality_check from Control_Globals where k = 'accountLockdownFunctionEnabled';

    # check if lockdown functionality enabled
    if functionality_check != 'true' then
        leave procedure_label;
    end if;

    select ID, is_locked_out, lockdown_start into target_account_ID, is_locked, lock_date from Account where ID = target_account_ID;

    if target_account_ID = -1 then
        signal sqlstate '45000' set message_text = 'User ID Invalid';
    end if;

    if is_locked and timestampdiff(minute, lock_date, now()) >= 45 then
        update Account set is_locked_out = false where ID = target_account_ID;
    end if;
end;

create table if not exists Subscription_Type (
                                                 ID integer primary key not null auto_increment,

                                                 name varchar(64) unique,

                                                 count_factor integer default 1000 not null, # how many responses/inputs per cost ( i.e. cost = survey_count_completions_cost / count_factor : 0.05 per 1000 completions )

                                                 survey_days_lifetime                                    int not null default 14, # no. of days a survey remains active
                                                 survey_lifetime_extension_week_completion_count_cost    float not null default 0.1, # cost of weekly extension, per completions count_factor

                                                 survey_count_completions_cost                           float not null default 0.05, # cost of completions per count_factor

                                                 response_limit integer default 1000,                # max responses allowed for this sub

                                                 is_group_subscription boolean not null              # represents a group ( org. / corpo. sub type )
);

insert into Subscription_Type (name, is_group_subscription, survey_days_lifetime, survey_lifetime_extension_week_completion_count_cost, survey_count_completions_cost, response_limit) values
('Free', false, 14, 0, 1, 100),             # free sub, not corpo., 2 weeks lifetime, no price, expensive per week extension, low completion count
('Standard', false, 14, 0.1, 0.05, 10000), # std sub, not corpo, 2 weeks lifetime, 0.1 per 1000 completions, 0.05 extension per 1000 completions, 10k completion max
('Premium', false, 21, 0.11, 0.045, 15000), # premium, not corpo, 3 weeks, 0.11 per 1000 comp, 0.045 ext per 1000 comp, 15k compl total
('Enterprise', true, 28, 0.12, 0.04, 50000), # ent, corpo, 4 weeks, 0.12 per 1000, 0.04 ext per 1000, 50k compl total
('Professional', true, 54, 0.15, 0.03, null); # pro, corpo, 8 weeks, 0.15 per 1000, 0.03 ext per 1000, no compl limit

create table if not exists Tool (
                                    ID integer primary key not null auto_increment,

                                    name varchar(64) unique, # cloud tool name ( service name )

                                    count_factor integer default 1000 not null, # scaling per inputs ( i.e. 0.05 per 1000 inputs )
    #  ^
                                    input_count_cost float not null # cost per count_factor of inputs
);

insert into Tool
(name, input_count_cost) values
('Response Emotional Analysis', 0.5), # emotional analysis tool, 0.5 per 1000 inputs
('Response Batch Translation', 0.01), # translator, 0.01 per 1000 in
('Response Graph Representation', 0.3), # 0.3 per 1000 in, graph gen
('Response Time and Trace Data', 0.1), # time & trace ( when, from where, locations etc, 0.1 per 1000 )
('Response File Exportation', 0.3),    # data exports in text formats , 0.3 per 1000
('Response Data and Prediction Analysis', 0.8), # data - age groups, resp. length, predictions etc. 0.8 per 1000
('Response Compound & Custom Process', 0.01);  # compound process = link of other tools ( i.e. translate - emotional analysis - prediction - export ). custom = user defined ( uploaded )


create table if not exists Subscription_Tool_Associations (
                                                              ID integer primary key not null auto_increment,

                                                              subscription_type_ID integer not null,  # tool linked to what sub
                                                              tool_ID integer not null, # what tool

                                                              constraint unique Subscription_Tool_Unique (subscription_type_ID, tool_ID),  # unique tool & sub

                                                              constraint foreign key Subscription_Tool_Valid_Subscription (subscription_type_ID) references Subscription_Type(ID) on delete cascade,
                                                              constraint foreign key Subscription_Tool_Valid_Tool (tool_ID) references Tool(ID) on delete cascade,

                                                              cost_ratio float not null default 1.0, # scaling ratio of cost ( from 0 to 100% [ 0.0f - 1.0f ]

                                                              check (cost_ratio >= 0.0 and cost_ratio <= 1.0), # validity check

                                                              data_input_count_limit integer not null default 1000 # limit of tool usage ( input limit per one usage ( max input ))
);

insert into Subscription_Tool_Associations (subscription_type_ID, tool_ID, cost_ratio, data_input_count_limit) values
((select ID from Subscription_Type where name = 'Free'), (select ID from Tool where name = 'Response Batch Translation'), 0, 5), # free gets only translate

((select ID from Subscription_Type where name = 'Standard'), (select ID from Tool where name = 'Response Batch Translation'), 1, 10000), # translate for large inputs
((select ID from Subscription_Type where name = 'Standard'), (select ID from Tool where name = 'Response File Exportation'), 1, 100), # export up to 100 in one archive
((select ID from Subscription_Type where name = 'Standard'), (select ID from Tool where name = 'Response Compound & Custom Process'), 1, 10000), # chain up to 10000 inputs

((select ID from Subscription_Type where name = 'Premium'), (select ID from Tool where name = 'Response Batch Translation'), 0.5, 20000), # translate up to 10000 at 1/2 cost
((select ID from Subscription_Type where name = 'Premium'), (select ID from Tool where name = 'Response File Exportation'), 0.9, 1000), # export up to 1000 in one go
((select ID from Subscription_Type where name = 'Premium'), (select ID from Tool where name = 'Response Compound & Custom Process'), 0.9, 50000), # chain up to 50k
((select ID from Subscription_Type where name = 'Premium'), (select ID from Tool where name = 'Response Graph Representation'), 1, 500), # represent up to 500 in a graph based on repeated data

((select ID from Subscription_Type where name = 'Enterprise'), (select ID from Tool where name = 'Response Batch Translation'), 0.8, 50000),
((select ID from Subscription_Type where name = 'Enterprise'), (select ID from Tool where name = 'Response File Exportation'), 0.9, 500),
((select ID from Subscription_Type where name = 'Enterprise'), (select ID from Tool where name = 'Response Compound & Custom Process'), 0.6, 10000),
((select ID from Subscription_Type where name = 'Enterprise'), (select ID from Tool where name = 'Response Emotional Analysis'), 1, 20000), # analyse up to 20k inputs for emotional text ratios
((select ID from Subscription_Type where name = 'Enterprise'), (select ID from Tool where name = 'Response Graph Representation'), 1, 20000),

((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Batch Translation'), 0.5, 100000),
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response File Exportation'), 0.8, 5000),
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Compound & Custom Process'), 0.3, 100000),
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Emotional Analysis'), 0.7, 100000),
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Graph Representation'), 0.6, 100000),
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Data and Prediction Analysis'), 1, 5000), # predict up to 5k inputs
((select ID from Subscription_Type where name = 'Professional'), (select ID from Tool where name = 'Response Time and Trace Data'), 1, 5000); # traceback location & time for inputs for up to 5k

# represents an active sub, taxed every 30 days
create table if not exists Active_Subscription (
                                                   ID integer primary key auto_increment not null,

                                                   subscription_type_ID integer not null, # sub type

                                                   current_response_count integer not null default 0, # count of responses out of the max sub type limit

                                                   last_renewal_date datetime not null default now(),
                                                   next_renewal_date datetime not null default timestampadd(day, 30, now()),

                                                   current_due_amount float not null default 0, # tab thus far

                                                   constraint foreign key Active_Subscription_Type_Valid(subscription_type_ID) references Subscription_Type(ID) on delete cascade
);

#regular subs
create table if not exists Active_Member_Subscription (
                                                          ID integer primary key auto_increment not null,

                                                          account_ID integer not null, # account bound to
                                                          subscription_ID integer not null,

                                                          constraint unique Active_Unique (account_ID), # an account can have ONE sub type active

#     check ( ( select is_group_subscription from Subscription where ID = ( select subscription_type_ID from Active_Subscription where ID = subscription_ID ) ) = false ),

                                                          constraint foreign key Active_Member_Subscription_Valid_Subscription(subscription_ID) references Subscription_Type(ID) on delete cascade,
                                                          constraint foreign key Active_Member_Subscription_Member_Valid(account_ID) references Account(ID) on delete cascade
);

#same but for Groups
create table if not exists Active_Group_Subscription (
                                                         ID integer primary key auto_increment not null,

                                                         group_ID integer not null,
                                                         subscription_ID integer not null,

                                                         constraint unique Active_Group_Unique (group_ID),

#     check ( ( select is_group_subscription from Subscription where ID = ( select subscription_type_ID from Active_Subscription where ID = subscription_ID ) ) = true ),

                                                         constraint foreign key Active_Group_Subscription_Valid_Subscription(subscription_ID) references Subscription_Type(ID) on delete cascade,
                                                         constraint foreign key Active_Group_Subscription_Group_Valid(group_ID) references Group_Account(ID) on delete cascade
);

# survey
create table if not exists Survey (
                                      ID integer primary key auto_increment not null,

                                      name varchar(64) not null,

                                      date_created datetime not null default now(),

                                      subscription_used integer not null, # what sub used to create it, used to calculate costs

                                      extended_lifetime_days integer not null default 0, # days extended

                                      constraint foreign key Survey_Valid_Sub (subscription_used) references Active_Subscription (ID) on delete cascade
);

create table if not exists Survey_Ownership (
                                                ID integer primary key auto_increment not null,

                                                survey_ID integer not null,
                                                creator_user_ID integer not null, # owned by a person
                                                creator_group_ID integer, # can use company / group account to mitigate sub

                                                constraint unique One_Survey_Creator_Constraint (survey_ID, creator_user_ID),
                                                constraint unique One_Survey_Group_Constraint (survey_ID, creator_group_ID),

                                                constraint foreign key Survey_Ownership_Valid_Survey (survey_ID) references Survey(ID) on delete cascade,
                                                constraint foreign key Survey_Ownership_Valid_User (creator_user_ID) references Account(ID) on delete cascade,
                                                constraint foreign key Survey_Ownership_Valid_Group (creator_group_ID) references Group_Account(ID) on delete set null
);

create table if not exists Survey_Response_Location (
                                                        ID integer primary key auto_increment not null,

                                                        survey_ID integer not null, # for which survey

                                                        survey_response longtext default null,

                                                        constraint foreign key Survey_Response_Valid_Survey (survey_ID) references Survey (ID) on delete cascade
);

create table Survey_Question_Answer_Type (
                                             ID integer primary key auto_increment not null,

                                             type varchar(64) not null unique
);

insert into Survey_Question_Answer_Type (type) values
('text'), # raspuns in text
('yesno'), # da / nu
('score'); # 1 - n: how ... do you feel about ... ?

create table if not exists Survey_Question (
                                               ID integer primary key auto_increment not null,

                                               survey_ID integer not null,

                                               question_number integer default 0,

                                               question_text varchar(256),

                                               constraint foreign key Survey_Question_Valid_To_Survey (survey_ID) references Survey(ID) on delete cascade
);

insert into Active_Subscription (subscription_type_ID) values (1);
insert into Survey (name, subscription_used) values ('test', 1);
insert into Survey_Question (survey_ID, question_text) values (1, 'test4');

create trigger if not exists Survey_Question_Number_Auto_Increment before insert on Survey_Question for each row
begin
    declare rownum integer;
    set rownum = -1;
    select count(*) into rownum from Survey_Question where survey_ID = new.survey_ID;

    if rownum != 0 then
        set new.question_number = ( select max(question_number) + 1 from Survey_Question where survey_ID = new.survey_ID );
        #         update Survey_Question set question_number = (select max(question_number) + 1 from Survey_Question where survey_ID = new.survey_ID) where survey_ID = new.survey_ID;
#         new.question_number = (select max(question_number) + 1 from Survey_Question where survey_ID = new.survey_ID);
#     else set new.question_number = 1 ;
    else
        set new.question_number = 1;
#         update Survey_Question set question_number = 1 where survey_ID = new.survey_ID;
    end if;

end;




# option_names : numele optiunilor ( gen la yesno / rating : rating 1: Unpleasant, rating 5: Neutral, rating 10: Positive in json : {1: "Unpleasant", 5: ...} )
# daca nu ai nume la optiuni, lasa null
create table if not exists Survey_Question_Answer_Type_Association ( # o intrebarea poate avea un rasp atat yes/no + text, sau yes, if yes -> rate -> text, sau doar text / rate / yesno
                                                                       ID integer primary key auto_increment not null,

                                                                       survey_question_ID integer not null,
                                                                       survey_question_answer_type_ID integer not null,

                                                                       option_names varchar (512) default null,


                                                                       constraint foreign key Survey_Question_Assoc_Valid (survey_question_ID) references Survey_Question(ID) on delete cascade,
                                                                       constraint foreign key Survey_Question_Type_Assoc_Valid (survey_question_answer_type_ID) references Survey_Question_Answer_Type (ID) on delete cascade
);

# all of the above, copied for ML
create table if not exists Survey_Copy (
                                           ID integer primary key auto_increment not null,

                                           date_created datetime not null default now(),

                                           subscription_type_used integer not null,

                                           extended_lifetime_days integer not null default 0,

                                           constraint foreign key Survey_Copy_Valid_Sub_Type (subscription_type_used) references Subscription_Type (ID) on delete cascade
);

create table if not exists Survey_Ownership_Copy (
                                                     ID integer primary key auto_increment not null,

                                                     survey_copy_ID integer not null,
                                                     creator_user_ID integer not null,
                                                     creator_group_ID integer,

                                                     constraint unique One_Survey_Copy_Creator_Constraint (survey_copy_ID, creator_user_ID),
                                                     constraint unique One_Survey_Copy_Group_Constraint (survey_copy_ID, creator_group_ID),

                                                     constraint foreign key Survey_Ownership_Copy_Valid_Survey (survey_copy_ID) references Survey_Copy(ID) on delete cascade,
                                                     constraint foreign key Survey_Ownership_Copy_Valid_User (creator_user_ID) references Account(ID) on delete cascade,
                                                     constraint foreign key Survey_Ownership_Copy_Valid_Group (creator_group_ID) references Group_Account(ID) on delete set null
);

create table if not exists Survey_Response_Location_Copy (
                                                             ID integer primary key auto_increment not null,

                                                             survey_copy_ID integer not null,

                                                             response longtext default null,

                                                             constraint foreign key Survey_Response_Valid_Survey_Copy (survey_copy_ID) references Survey_Copy (ID) on delete cascade
);
