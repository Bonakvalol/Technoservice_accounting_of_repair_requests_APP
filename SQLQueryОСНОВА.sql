
USE master;
GO

-- Удаление существующей базы
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'RepairRequestsDB')
BEGIN
    ALTER DATABASE RepairRequestsDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RepairRequestsDB;
    PRINT 'Существующая база данных RepairRequestsDB удалена';
END
GO

-- Создание базы данных
CREATE DATABASE RepairRequestsDB;
GO

USE RepairRequestsDB;
GO

PRINT 'База данных RepairRequestsDB создана';
GO

-- 1. ТАБЛИЦА: Клиенты (Clients)
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
    CompanyName NVARCHAR(100),
    Phone NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100),
    Address NVARCHAR(300),
    RegistrationDate DATETIME DEFAULT GETDATE(),
    Notes NVARCHAR(500)
);
PRINT 'Таблица Clients создана';
GO

-- 2. ТАБЛИЦА: Типы оборудования (EquipmentTypes)
CREATE TABLE EquipmentTypes (
    EquipmentTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    Category NVARCHAR(50),
    AverageRepairTime INT -- в часах
);
PRINT 'Таблица EquipmentTypes создана';
GO

-- 3. ТАБЛИЦА: Оборудование (Equipment)
CREATE TABLE Equipment (
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT NOT NULL,
    EquipmentTypeID INT NOT NULL,
    SerialNumber NVARCHAR(50) NOT NULL UNIQUE,
    Model NVARCHAR(100),
    PurchaseDate DATE,
    WarrantyUntil DATE,
    Status NVARCHAR(20) DEFAULT 'Исправен' 
        CHECK (Status IN ('Исправен', 'В ремонте', 'Списан', 'Резерв')),
    LastMaintenanceDate DATE,
    Notes NVARCHAR(500),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE CASCADE,
    FOREIGN KEY (EquipmentTypeID) REFERENCES EquipmentTypes(EquipmentTypeID)
);
PRINT 'Таблица Equipment создана';
GO

-- 4. ТАБЛИЦА: Типы неисправностей (FaultTypes)
CREATE TABLE FaultTypes (
    FaultTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    SeverityLevel INT DEFAULT 1 CHECK (SeverityLevel BETWEEN 1 AND 5),
    EstimatedRepairHours INT
);
PRINT 'Таблица FaultTypes создана';
GO

-- 5. ТАБЛИЦА: Сотрудники (Employees)
CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
    Position NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50),
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    HireDate DATE DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    Specialization NVARCHAR(200)
);
PRINT 'Таблица Employees создана';
GO

-- 6. ТАБЛИЦА: Заявки на ремонт (RepairRequests)
CREATE TABLE RepairRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    RequestNumber NVARCHAR(20) NOT NULL UNIQUE,
    ClientID INT NOT NULL,
    EquipmentID INT NOT NULL,
    FaultTypeID INT NOT NULL,
    RequestDate DATETIME DEFAULT GETDATE(),
    ProblemDescription NVARCHAR(1000) NOT NULL,
    Priority INT DEFAULT 3 CHECK (Priority BETWEEN 1 AND 5), -- 1-высокий, 5-низкий
    Status NVARCHAR(20) DEFAULT 'В ожидании' 
        CHECK (Status IN ('В ожидании', 'В работе', 'Выполнено', 'Отменено', 'На паузе')),
    AssignedToEmployeeID INT,
    EstimatedCompletionDate DATE,
    ActualCompletionDate DATETIME,
    CreatedByEmployeeID INT,
    Notes NVARCHAR(500),
    CONSTRAINT CHK_Dates CHECK (ActualCompletionDate >= RequestDate),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (EquipmentID) REFERENCES Equipment(EquipmentID),
    FOREIGN KEY (FaultTypeID) REFERENCES FaultTypes(FaultTypeID),
    FOREIGN KEY (AssignedToEmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (CreatedByEmployeeID) REFERENCES Employees(EmployeeID)
);
PRINT 'Таблица RepairRequests создана';
GO

-- 7. ТАБЛИЦА: Запчасти (SpareParts)
CREATE TABLE SpareParts (
    PartID INT IDENTITY(1,1) PRIMARY KEY,
    PartNumber NVARCHAR(50) NOT NULL UNIQUE,
    PartName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    Category NVARCHAR(50),
    UnitPrice DECIMAL(10,2) NOT NULL,
    QuantityInStock INT DEFAULT 0,
    MinimumStockLevel INT DEFAULT 5,
    Supplier NVARCHAR(100),
    IsActive BIT DEFAULT 1
);
PRINT 'Таблица SpareParts создана';
GO

-- 8. ТАБЛИЦА: Использованные запчасти (UsedParts)
CREATE TABLE UsedParts (
    UsedPartID INT IDENTITY(1,1) PRIMARY KEY,
    RequestID INT NOT NULL,
    PartID INT NOT NULL,
    QuantityUsed INT NOT NULL DEFAULT 1,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalPrice DECIMAL(10,2),
    UsedDate DATETIME DEFAULT GETDATE(),
    InstalledByEmployeeID INT,
    WarrantyUntil DATE,
    FOREIGN KEY (RequestID) REFERENCES RepairRequests(RequestID) ON DELETE CASCADE,
    FOREIGN KEY (PartID) REFERENCES SpareParts(PartID),
    FOREIGN KEY (InstalledByEmployeeID) REFERENCES Employees(EmployeeID)
);
PRINT 'Таблица UsedParts создана';
GO

-- ============================================
-- СОЗДАНИЕ ИНДЕКСОВ ДЛЯ ОПТИМИЗАЦИИ
-- ============================================

CREATE INDEX IDX_Clients_Name ON Clients(LastName, FirstName);
CREATE INDEX IDX_Clients_Phone ON Clients(Phone);
CREATE INDEX IDX_Equipment_Serial ON Equipment(SerialNumber);
CREATE INDEX IDX_Equipment_Client ON Equipment(ClientID);
CREATE INDEX IDX_RepairRequests_Number ON RepairRequests(RequestNumber);
CREATE INDEX IDX_RepairRequests_Status ON RepairRequests(Status);
CREATE INDEX IDX_RepairRequests_Dates ON RepairRequests(RequestDate, ActualCompletionDate);
CREATE INDEX IDX_RepairRequests_Client ON RepairRequests(ClientID);
CREATE INDEX IDX_RepairRequests_Employee ON RepairRequests(AssignedToEmployeeID);
CREATE INDEX IDX_Employees_Active ON Employees(EmployeeID) WHERE IsActive = 1;
-- Исправленный фильтрованный индекс для запчастей с низким запасом
CREATE INDEX IDX_SpareParts_LowStock ON SpareParts(PartID) 
WHERE QuantityInStock < MinimumStockLevel;
PRINT 'Индексы созданы';
GO

-- ============================================
-- УДАЛЕНИЕ СУЩЕСТВУЮЩИХ ТРИГГЕРОВ И ПРОЦЕДУР
-- ============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'TR_UsedParts_CalculateTotal')
    DROP TRIGGER TR_UsedParts_CalculateTotal;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'TR' AND name = 'TR_RepairRequests_UpdateEquipmentStatus')
    DROP TRIGGER TR_RepairRequests_UpdateEquipmentStatus;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GetCompletedRequestsCount')
    DROP PROCEDURE sp_GetCompletedRequestsCount;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GetAverageRepairTime')
    DROP PROCEDURE sp_GetAverageRepairTime;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_AddRepairRequest')
    DROP PROCEDURE sp_AddRepairRequest;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_GetAllRequests')
    DROP PROCEDURE sp_GetAllRequests;
GO

-- ============================================
-- СОЗДАНИЕ ТРИГГЕРОВ
-- ============================================

-- Триггер для автоматического расчета стоимости использованных запчастей
CREATE TRIGGER TR_UsedParts_CalculateTotal
ON UsedParts
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE up
    SET up.TotalPrice = i.QuantityUsed * i.UnitPrice
    FROM UsedParts up
    INNER JOIN inserted i ON up.UsedPartID = i.UsedPartID;
END;
GO
PRINT 'Триггер TR_UsedParts_CalculateTotal создан';
GO

-- Триггер для обновления статуса оборудования при изменении статуса заявки
CREATE TRIGGER TR_RepairRequests_UpdateEquipmentStatus
ON RepairRequests
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Обновляем статус оборудования при изменении статуса заявки
    UPDATE e
    SET e.Status = 
        CASE 
            WHEN i.Status = 'В работе' THEN 'В ремонте'
            WHEN i.Status = 'Выполнено' THEN 'Исправен'
            ELSE e.Status
        END
    FROM Equipment e
    INNER JOIN inserted i ON e.EquipmentID = i.EquipmentID
    INNER JOIN deleted d ON i.RequestID = d.RequestID
    WHERE i.Status <> d.Status;
END;
GO
PRINT 'Триггер TR_RepairRequests_UpdateEquipmentStatus создан';
GO

-- ============================================
-- СОЗДАНИЕ ХРАНИМЫХ ПРОЦЕДУР (по требованиям ТЗ)
-- ============================================

-- Процедура 1: Расчет количества выполненных заявок (требование 2.5)
CREATE PROCEDURE sp_GetCompletedRequestsCount
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @EmployeeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) AS CompletedCount,
        ISNULL(SUM(DATEDIFF(HOUR, r.RequestDate, r.ActualCompletionDate)), 0) AS TotalRepairHours
    FROM RepairRequests r
    WHERE r.Status = 'Выполнено'
        AND (@StartDate IS NULL OR CAST(r.RequestDate AS DATE) >= @StartDate)
        AND (@EndDate IS NULL OR CAST(r.RequestDate AS DATE) <= @EndDate)
        AND (@EmployeeID IS NULL OR r.AssignedToEmployeeID = @EmployeeID);
END;
GO
PRINT 'Процедура sp_GetCompletedRequestsCount создана';
GO

-- Процедура 2: Расчет среднего времени выполнения заявки (требование 2.5)
CREATE PROCEDURE sp_GetAverageRepairTime
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @FaultTypeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ISNULL(AVG(DATEDIFF(HOUR, r.RequestDate, r.ActualCompletionDate)), 0) AS AverageHours,
        ISNULL(MIN(DATEDIFF(HOUR, r.RequestDate, r.ActualCompletionDate)), 0) AS MinHours,
        ISNULL(MAX(DATEDIFF(HOUR, r.RequestDate, r.ActualCompletionDate)), 0) AS MaxHours,
        COUNT(*) AS TotalCompleted
    FROM RepairRequests r
    WHERE r.Status = 'Выполнено'
        AND r.ActualCompletionDate IS NOT NULL
        AND (@StartDate IS NULL OR CAST(r.RequestDate AS DATE) >= @StartDate)
        AND (@EndDate IS NULL OR CAST(r.RequestDate AS DATE) <= @EndDate)
        AND (@FaultTypeID IS NULL OR r.FaultTypeID = @FaultTypeID);
END;
GO
PRINT 'Процедура sp_GetAverageRepairTime создана';
GO

-- Процедура 3: Добавление новой заявки на ремонт
CREATE PROCEDURE sp_AddRepairRequest
    @ClientID INT,
    @EquipmentID INT,
    @FaultTypeID INT,
    @ProblemDescription NVARCHAR(1000),
    @Priority INT = 3,
    @CreatedByEmployeeID INT,
    @NewRequestID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @NewRequestID = -1;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Генерация номера заявки
        DECLARE @RequestNumber NVARCHAR(20);
        DECLARE @Year INT = YEAR(GETDATE());
        DECLARE @Month INT = MONTH(GETDATE());
        
        SELECT @RequestNumber = 'RR-' + CAST(@Year AS NVARCHAR(4)) + 
               RIGHT('0' + CAST(@Month AS NVARCHAR(2)), 2) + 
               '-' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(RequestNumber, 9, 4) AS INT)), 0) + 1 AS NVARCHAR(4)), 4)
        FROM RepairRequests
        WHERE RequestNumber LIKE 'RR-' + CAST(@Year AS NVARCHAR(4)) + 
              RIGHT('0' + CAST(@Month AS NVARCHAR(2)), 2) + '-%';
        
        IF @RequestNumber IS NULL
            SET @RequestNumber = 'RR-' + CAST(@Year AS NVARCHAR(4)) + 
                                 RIGHT('0' + CAST(@Month AS NVARCHAR(2)), 2) + '-0001';
        
        -- Вставка заявки
        INSERT INTO RepairRequests (
            RequestNumber, ClientID, EquipmentID, FaultTypeID,
            ProblemDescription, Priority, CreatedByEmployeeID
        )
        VALUES (
            @RequestNumber, @ClientID, @EquipmentID, @FaultTypeID,
            @ProblemDescription, @Priority, @CreatedByEmployeeID
        );
        
        SET @NewRequestID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO
PRINT 'Процедура sp_AddRepairRequest создана';
GO

-- Процедура 4: Получение всех заявок с фильтрацией
CREATE PROCEDURE sp_GetAllRequests
    @Status NVARCHAR(20) = NULL,
    @EmployeeID INT = NULL,
    @ClientID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.RequestID,
        r.RequestNumber,
        r.RequestDate,
        r.ProblemDescription,
        r.Priority,
        r.Status,
        r.ActualCompletionDate,
        c.ClientID,
        c.LastName + ' ' + c.FirstName + ' ' + ISNULL(c.MiddleName, '') AS ClientFullName,
        c.Phone AS ClientPhone,
        -- Исправлено: изменено e.EquipmentID на eq.EquipmentID
        eq.EquipmentID,
        eq.SerialNumber,
        eq.Model,
        et.TypeName AS EquipmentType,
        ft.TypeName AS FaultType,
        emp.EmployeeID AS AssignedEmployeeID,
        emp.LastName + ' ' + emp.FirstName AS EmployeeFullName,
        DATEDIFF(HOUR, r.RequestDate, ISNULL(r.ActualCompletionDate, GETDATE())) AS HoursSpent,
        ISNULL(up.TotalPartsCost, 0) AS PartsCost
    FROM RepairRequests r
    INNER JOIN Clients c ON r.ClientID = c.ClientID
    INNER JOIN Equipment eq ON r.EquipmentID = eq.EquipmentID
    INNER JOIN EquipmentTypes et ON eq.EquipmentTypeID = et.EquipmentTypeID
    INNER JOIN FaultTypes ft ON r.FaultTypeID = ft.FaultTypeID
    LEFT JOIN Employees emp ON r.AssignedToEmployeeID = emp.EmployeeID
    LEFT JOIN (
        SELECT RequestID, SUM(TotalPrice) AS TotalPartsCost
        FROM UsedParts
        GROUP BY RequestID
    ) up ON r.RequestID = up.RequestID
    WHERE (@Status IS NULL OR r.Status = @Status)
        AND (@EmployeeID IS NULL OR r.AssignedToEmployeeID = @EmployeeID)
        AND (@ClientID IS NULL OR r.ClientID = @ClientID)
    ORDER BY 
        CASE 
            WHEN r.Priority = 1 THEN 1
            WHEN r.Priority = 2 THEN 2
            WHEN r.Priority = 3 THEN 3
            ELSE 4
        END,
        r.RequestDate DESC;
END;
GO
PRINT 'Процедура sp_GetAllRequests создана';
GO

-- ============================================
-- ЗАПОЛНЕНИЕ ТАБЛИЦ ТЕСТОВЫМИ ДАННЫМИ
-- ============================================

PRINT 'Начало заполнения тестовыми данными...';
GO

-- 1. Заполнение Клиентов (по 5 записей)
PRINT '1. Добавление клиентов...';
INSERT INTO Clients (LastName, FirstName, MiddleName, CompanyName, Phone, Email)
VALUES 
    ('Иванов', 'Алексей', 'Петрович', 'ООО "Технопром"', '+79161234567', 'ivanov@techprom.ru'),
    ('Смирнова', 'Мария', 'Игоревна', 'ЗАО "Электросила"', '+79161234568', 'smirnova@electro.ru'),
    ('Петров', 'Дмитрий', 'Сергеевич', 'ИП Петров Д.С.', '+79161234569', 'petrov@mail.ru'),
    ('Козлова', 'Ольга', 'Викторовна', 'ООО "Металлстрой"', '+79161234570', 'kozlova@metal.ru'),
    ('Сидоров', 'Андрей', 'Александрович', 'АО "Машинострой"', '+79161234571', 'sidorov@mashin.ru');
PRINT '   Добавлено 5 клиентов';
GO

-- 2. Заполнение Типов оборудования (по 5 записей)
PRINT '2. Добавление типов оборудования...';
INSERT INTO EquipmentTypes (TypeName, Description, Category, AverageRepairTime)
VALUES 
    ('Токарный станок', 'Токарный станок с ЧПУ', 'Станки', 8),
    ('Фрезерный станок', 'Фрезерный станок по металлу', 'Станки', 10),
    ('Компрессор', 'Воздушный компрессор промышленный', 'Пневмооборудование', 4),
    ('Принтер', 'Лазерный принтер A3', 'Офисная техника', 2),
    ('Сервер', 'Промышленный сервер хранения данных', 'ИТ-оборудование', 12);
PRINT '   Добавлено 5 типов оборудования';
GO

-- 3. Заполнение Оборудования (по 5 записей)
PRINT '3. Добавление оборудования...';
INSERT INTO Equipment (ClientID, EquipmentTypeID, SerialNumber, Model, PurchaseDate, Status)
VALUES 
    (1, 1, 'TS-2023-001', 'ТС-16У', '2023-01-15', 'Исправен'),
    (2, 2, 'FS-2022-045', 'ФС-250', '2022-05-20', 'В ремонте'),
    (3, 3, 'CP-2021-123', 'КВ-7/10', '2021-08-10', 'Исправен'),
    (4, 4, 'PR-2023-078', 'HP LaserJet', '2023-03-05', 'Резерв'),
    (5, 5, 'SR-2022-156', 'Dell PowerEdge', '2022-11-30', 'Исправен');
PRINT '   Добавлено 5 единиц оборудования';
GO

-- 4. Заполнение Типов неисправностей (по 5 записей)
PRINT '4. Добавление типов неисправностей...';
INSERT INTO FaultTypes (TypeName, Description, SeverityLevel, EstimatedRepairHours)
VALUES 
    ('Механический износ', 'Износ механических частей', 3, 6),
    ('Электронная неисправность', 'Проблемы с электроникой', 4, 8),
    ('Программный сбой', 'Сбои в программном обеспечении', 2, 3),
    ('Гидравлическая утечка', 'Утечка гидравлической жидкости', 5, 10),
    ('Перегрев', 'Перегрев компонентов', 3, 4);
PRINT '   Добавлено 5 типов неисправностей';
GO

-- 5. Заполнение Сотрудников (по 5 записей)
PRINT '5. Добавление сотрудников...';
INSERT INTO Employees (LastName, FirstName, MiddleName, Position, Department, Phone, Specialization)
VALUES 
    ('Васильев', 'Игорь', 'Сергеевич', 'Инженер-ремонтник', 'Ремонтный отдел', '+79161111111', 'Станки, механика'),
    ('Николаева', 'Елена', 'Андреевна', 'Электроник', 'Ремонтный отдел', '+79161111112', 'Электроника, схемы'),
    ('Федоров', 'Михаил', 'Витальевич', 'ИТ-специалист', 'ИТ-отдел', '+79161111113', 'Серверы, сети'),
    ('Ковалева', 'Анна', 'Дмитриевна', 'Менеджер', 'Отдел приема', '+79161111114', 'Координация, клиенты'),
    ('Алексеев', 'Павел', 'Игоревич', 'Мастер', 'Ремонтный отдел', '+79161111115', 'Гидравлика, пневматика');
PRINT '   Добавлено 5 сотрудников';
GO

-- 6. Заполнение Запчастей (по 5 записей)
PRINT '6. Добавление запчастей...';
INSERT INTO SpareParts (PartNumber, PartName, Description, Category, UnitPrice, QuantityInStock)
VALUES 
    ('BEAR-001', 'Подшипник радиальный', 'Подшипник 6205', 'Механика', 1250.50, 15),
    ('MOTOR-005', 'Электродвигатель', 'Двигатель 1.5 кВт', 'Электрика', 8500.00, 5),
    ('FAN-012', 'Вентилятор охлаждения', 'Вентилятор 120мм', 'Охлаждение', 650.00, 20),
    ('CABLE-023', 'Кабель питания', 'Кабель 3x1.5mm²', 'Электрика', 150.00, 100),
    ('PUMP-008', 'Гидравлический насос', 'Насос НШ-10', 'Гидравлика', 12000.00, 3);
PRINT '   Добавлено 5 видов запчастей';
GO

-- 7. Заполнение Заявок на ремонт (по 5 записей)
PRINT '7. Добавление заявок на ремонт...';
INSERT INTO RepairRequests (RequestNumber, ClientID, EquipmentID, FaultTypeID, 
                          ProblemDescription, Priority, Status, 
                          AssignedToEmployeeID, CreatedByEmployeeID, 
                          RequestDate, ActualCompletionDate)
VALUES 
    ('RR-2024-01-0001', 1, 1, 1, 'Сильный люфт шпинделя, требуется замена подшипников', 2, 'Выполнено', 1, 4, '2024-01-15 09:30:00', '2024-01-16 16:45:00'),
    ('RR-2024-01-0002', 2, 2, 2, 'Не запускается ЧПУ, ошибка E-125', 1, 'В работе', 2, 4, '2024-01-20 11:15:00', NULL),
    ('RR-2024-02-0001', 3, 3, 4, 'Утечка масла из гидравлической системы', 3, 'В ожидании', NULL, 4, '2024-02-05 14:20:00', NULL),
    ('RR-2024-02-0002', 4, 4, 3, 'Принтер не печатает, драйвер выдает ошибку', 4, 'Выполнено', 3, 4, '2024-02-10 10:00:00', '2024-02-10 12:30:00'),
    ('RR-2024-02-0003', 5, 5, 5, 'Сервер перегревается и отключается', 2, 'Выполнено', 3, 4, '2024-02-12 08:45:00', '2024-02-13 11:20:00');
PRINT '   Добавлено 5 заявок на ремонт';
GO

-- 8. Заполнение Использованных запчастей (по 5 записей)
PRINT '8. Добавление использованных запчастей...';
INSERT INTO UsedParts (RequestID, PartID, QuantityUsed, UnitPrice, InstalledByEmployeeID)
VALUES 
    (1, 1, 2, 1250.50, 1),
    (4, 3, 1, 650.00, 3),
    (5, 3, 2, 650.00, 3),
    (5, 4, 5, 150.00, 3);
PRINT '   Добавлено 4 записи об использованных запчастях';
GO

-- ============================================
-- ПРОВЕРКА И ТЕСТИРОВАНИЕ
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'ПРОВЕРКА СОЗДАННЫХ ДАННЫХ:';
PRINT '============================================';

SELECT 'Клиенты' AS Таблица, COUNT(*) AS Количество FROM Clients
UNION ALL
SELECT 'Типы оборудования', COUNT(*) FROM EquipmentTypes
UNION ALL
SELECT 'Оборудование', COUNT(*) FROM Equipment
UNION ALL
SELECT 'Типы неисправностей', COUNT(*) FROM FaultTypes
UNION ALL
SELECT 'Сотрудники', COUNT(*) FROM Employees
UNION ALL
SELECT 'Запчасти', COUNT(*) FROM SpareParts
UNION ALL
SELECT 'Заявки на ремонт', COUNT(*) FROM RepairRequests
UNION ALL
SELECT 'Использованные запчасти', COUNT(*) FROM UsedParts;
GO

PRINT '';
PRINT '============================================';
PRINT 'ТЕСТИРОВАНИЕ ХРАНИМЫХ ПРОЦЕДУР:';
PRINT '============================================';
PRINT '';

-- Тест 1: Расчет количества выполненных заявок
PRINT '1. Тест sp_GetCompletedRequestsCount:';
EXEC sp_GetCompletedRequestsCount 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31';
PRINT '';

-- Тест 2: Расчет среднего времени выполнения
PRINT '2. Тест sp_GetAverageRepairTime:';
EXEC sp_GetAverageRepairTime 
    @StartDate = '2024-01-01',
    @EndDate = '2024-02-28';
PRINT '';

-- Тест 3: Получение всех заявок
PRINT '3. Тест sp_GetAllRequests:';
EXEC sp_GetAllRequests;
PRINT '';

-- Тест 4: Получение заявок в работе
PRINT '4. Тест sp_GetAllRequests (только в работе):';
EXEC sp_GetAllRequests @Status = 'В работе';
PRINT '';

-- Тест 5: Добавление новой заявки
PRINT '5. Тест sp_AddRepairRequest:';
DECLARE @NewRequestID INT;
EXEC sp_AddRepairRequest 
    @ClientID = 1,
    @EquipmentID = 1,
    @FaultTypeID = 1,
    @ProblemDescription = 'Тестовая заявка на ремонт',
    @Priority = 3,
    @CreatedByEmployeeID = 4,
    @NewRequestID = @NewRequestID OUTPUT;
PRINT '   Создана заявка с ID: ' + CAST(@NewRequestID AS NVARCHAR(10));
PRINT '';

PRINT '============================================';
PRINT 'БАЗА ДАННЫХ ДЛЯ УЧЕТА ЗАЯВОК НА РЕМОНТ УСПЕШНО СОЗДАНА!';
PRINT '============================================';
PRINT '';
PRINT 'Создано таблиц: 8 (в соответствии с ER-диаграммой)';
PRINT '';
PRINT 'Добавлено тестовых данных (по 5 записей в каждую таблицу):';
PRINT '• Клиенты: 5';
PRINT '• Типы оборудования: 5';
PRINT '• Оборудование: 5';
PRINT '• Типы неисправностей: 5';
PRINT '• Сотрудники: 5';
PRINT '• Запчасти: 5';
PRINT '• Заявки на ремонт: 5 + 1 тестовая';
PRINT '• Использованные запчасти: 4';
PRINT '';
PRINT 'Реализованы хранимые процедуры по требованиям ТЗ:';
PRINT '1. sp_GetCompletedRequestsCount - расчет количества выполненных заявок (треб. 2.5)';
PRINT '2. sp_GetAverageRepairTime - расчет среднего времени выполнения (треб. 2.5)';
PRINT '3. sp_AddRepairRequest - добавление новой заявки (треб. 2.1)';
PRINT '4. sp_GetAllRequests - получение всех заявок с фильтрацией (треб. 2.3)';
PRINT '';
PRINT 'Строка подключения для WPF приложения:';
PRINT 'Server=bd-kip.fa.ru;Database=RepairRequestsDB;User Id=sa;Password=1qaz!QAZ;TrustServerCertificate=True;';
PRINT '';
PRINT 'База данных готова к интеграции с WPF приложением!';
PRINT '============================================';
GO