CREATE DATABASE TareaProgramadaTres;
GO

USE TareaProgramadaTres;
GO

CREATE USER kaleb FOR LOGIN kaleb;
GO

ALTER ROLE db_owner ADD MEMBER kaleb;
GO

CREATE USER gabo FOR LOGIN gabo;
GO

ALTER ROLE db_owner ADD MEMBER gabo;
GO
