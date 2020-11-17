create table [template].[group]
(
    [id] int not null identity(0,1) constraint pk_template_group_id primary key
  , [name] varchar(30) not null constraint uq_template_group_login unique
);
