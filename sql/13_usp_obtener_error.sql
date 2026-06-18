USE [TareaProgramadaTres];
GO

CREATE PROCEDURE [dbo].[ObtenerError]
    @inCodigo INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    SELECT
        [E].[Codigo] AS [Codigo]
        , [E].[Descripcion] AS [Descripcion]
    FROM [dbo].[Error] AS [E]
    WHERE ([E].[Codigo] = @inCodigo);

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
