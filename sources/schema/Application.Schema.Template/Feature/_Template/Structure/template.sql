create table [template].[template]
(
    [id] int not null identity(0,1) constraint pk_template_template_id primary key clustered
  , [column1] varchar(30) not null
  , [column2] varchar(30) not null
  , [column3] varchar(30) not null
);
