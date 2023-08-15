create table [template].[user]
(
    [id] int not null identity(0,1) constraint pk_template_user_id primary key
  , [login] varchar(30) not null constraint uq_template_user_login unique
  , [givename] varchar(30) not null
  , [surname] varchar(30) not null
);
