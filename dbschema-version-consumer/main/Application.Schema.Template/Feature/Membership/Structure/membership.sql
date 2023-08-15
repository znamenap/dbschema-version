create table [template].[membership]
(
    [id] int not null identity(0,1) constraint pk_template_membership_id primary key
  , [user_id] int not null -- constraint fk_template_membership_user_id foreign key ([user_id]) references [template].[user] (id)
  , [group_id] int not null -- constraint fk_template_membership_group_id foreign key ([group_id]) references [template].[group] (id)
  , constraint uq_tempalte_membership_user_group unique nonclustered ([user_id], [group_id])
);
go

alter table [template].[membership] add 
    constraint fk_template_membership_group_id foreign key ([group_id]) references [template].[group] (id);
go

alter table [template].[membership] add 
    constraint fk_template_membership_user_id foreign key ([user_id]) references [template].[user] (id);
go

alter table [template].[membership] check constraint fk_template_membership_group_id, fk_template_membership_user_id;
go
