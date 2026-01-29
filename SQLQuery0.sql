USE RepairRequestsDB;
GO

-- Удаляем процедуру если существует
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GenerateReviewLink')
    DROP PROCEDURE sp_GenerateReviewLink;
GO

-- Новая процедура для обновления информации о QR-коде
CREATE PROCEDURE sp_UpdateQRCodeInfo
    @RequestID INT,
    @QRCodeData NVARCHAR(MAX) = NULL,
    @QRCodeGeneratedDate DATETIME = NULL
AS
BEGIN
    UPDATE RepairRequests 
    SET 
        QRCodePath = @QRCodeData,
        QRCodeGeneratedDate = ISNULL(@QRCodeGeneratedDate, GETDATE())
    WHERE RequestID = @RequestID;
END;
GO

-- Добавляем поле для даты генерации QR-кода если его нет
IF NOT EXISTS(SELECT * FROM sys.columns 
              WHERE Name = 'QRCodeGeneratedDate' 
              AND Object_ID = Object_ID('RepairRequests'))
BEGIN
    ALTER TABLE RepairRequests 
    ADD QRCodeGeneratedDate DATETIME NULL;
    PRINT 'Добавлено поле QRCodeGeneratedDate';
END
GO