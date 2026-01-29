USE RepairRequestsDB;
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

-- Удаляем процедуру если существует
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_UpdateQRCodeInfo')
    DROP PROCEDURE sp_UpdateQRCodeInfo;
GO

-- Новая процедура для обновления информации о QR-коде
CREATE PROCEDURE sp_UpdateQRCodeInfo
    @RequestID INT,
    @QRCodeData NVARCHAR(MAX) = NULL
AS
BEGIN
    UPDATE RepairRequests 
    SET 
        QRCodePath = @QRCodeData,
        QRCodeGeneratedDate = GETDATE()
    WHERE RequestID = @RequestID;
END;
GO

PRINT 'Процедура sp_UpdateQRCodeInfo создана';
GO