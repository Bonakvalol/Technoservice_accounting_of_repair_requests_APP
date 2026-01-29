USE RepairRequestsDB;
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
              WHERE Name = 'QRCodePath' 
              AND Object_ID = Object_ID('RepairRequests'))
BEGIN
    ALTER TABLE RepairRequests 
    ADD QRCodePath NVARCHAR(500) NULL;
    
    PRINT 'ƒобавлено поле QRCodePath дл€ хранени€ пути к QR-коду';
END
GO