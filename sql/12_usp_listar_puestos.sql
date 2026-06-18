USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[ListarPuestos]
    @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    SELECT
        [P].[id] AS [id]
        , [P].[Nombre] AS [Nombre]
    FROM [dbo].[Puesto] AS [P]
    ORDER BY [P].[Nombre];

END TRY
BEGIN CATCH

    INSERT [dbo].[DBError] (
        [UserName]
        , [ErrorNumber]
        , [ErrorState]
        , [ErrorSeverity]
        , [ErrorLine]
        , [ErrorProcedure]
        , [ErrorMessage]
        , [ErrorDateTime]
    )
    SELECT
        SUSER_SNAME()
        , ERROR_NUMBER()
        , ERROR_STATE()
        , ERROR_SEVERITY()
        , ERROR_LINE()
        , ERROR_PROCEDURE()
        , ERROR_MESSAGE()
        , GETDATE();

    SET @outResultCode = 50008;
    SELECT @outResultCode AS [outResultCode];

END CATCH

SET NOCOUNT OFF;
END;
GO
