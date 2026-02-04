USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ManagementCompanyDB')
BEGIN
    ALTER DATABASE ManagementCompanyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ManagementCompanyDB;
    PRINT 'База данных ManagementCompanyDB удалена';
END
GO

CREATE DATABASE ManagementCompanyDB;
GO

USE ManagementCompanyDB;
GO

PRINT 'База данных ManagementCompanyDB создана';
GO

-- Создание таблиц
CREATE TABLE Buildings (
    BuildingID INT IDENTITY(1,1) PRIMARY KEY,
    Address NVARCHAR(300) NOT NULL UNIQUE,
    Floors INT NOT NULL,
    ApartmentsCount INT NOT NULL,
    YearBuilt INT,
    TotalArea DECIMAL(10,2),
    ManagementStartDate DATE NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Активен'
        CHECK (Status IN ('Активен', 'На реконструкции', 'Закрыт')),
    Notes NVARCHAR(500)
);
GO

CREATE TABLE Apartments (
    ApartmentID INT IDENTITY(1,1) PRIMARY KEY,
    BuildingID INT NOT NULL,
    ApartmentNumber INT NOT NULL,
    OwnerFullName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    Area DECIMAL(8,2),
    RoomsCount INT,
    Status NVARCHAR(20) DEFAULT 'Заселена'
        CHECK (Status IN ('Заселена', 'Пустует', 'На ремонте', 'Продается')),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID) ON DELETE CASCADE
);
GO

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
GO

CREATE TABLE RepairRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    RequestNumber NVARCHAR(20) NOT NULL UNIQUE,
    BuildingID INT NOT NULL,
    ApartmentID INT,
    ApplicantFullName NVARCHAR(150) NOT NULL,
    ApplicantPhone NVARCHAR(20) NOT NULL,
    ProblemDescription NVARCHAR(1000) NOT NULL,
    RequestDate DATETIME DEFAULT GETDATE(),
    Priority INT DEFAULT 3 CHECK (Priority BETWEEN 1 AND 5),
    Status NVARCHAR(20) DEFAULT 'Открыта' 
        CHECK (Status IN ('Открыта', 'В работе', 'Заявка в работе', 'Заявка закрыта', 'Отменена')),
    AssignedToEmployeeID INT,
    EstimatedCompletionDate DATE,
    ActualCompletionDate DATETIME,
    CreatedByEmployeeID INT,
    Notes NVARCHAR(500),
    FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
    FOREIGN KEY (ApartmentID) REFERENCES Apartments(ApartmentID),
    FOREIGN KEY (AssignedToEmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (CreatedByEmployeeID) REFERENCES Employees(EmployeeID)
);
GO

CREATE TABLE RequestHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    RequestID INT NOT NULL,
    EmployeeID INT NOT NULL,
    ActionDate DATETIME DEFAULT GETDATE(),
    ActionType NVARCHAR(50) NOT NULL,
    Description NVARCHAR(500),
    OldStatus NVARCHAR(20),
    NewStatus NVARCHAR(20),
    FOREIGN KEY (RequestID) REFERENCES RepairRequests(RequestID) ON DELETE CASCADE,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);
GO

-- Создание индексов
CREATE INDEX IDX_Buildings_Address ON Buildings(Address);
CREATE INDEX IDX_Apartments_Building ON Apartments(BuildingID);
CREATE INDEX IDX_Apartments_Number ON Apartments(ApartmentNumber);
CREATE INDEX IDX_RepairRequests_Number ON RepairRequests(RequestNumber);
CREATE INDEX IDX_RepairRequests_Status ON RepairRequests(Status);
CREATE INDEX IDX_RepairRequests_Dates ON RepairRequests(RequestDate, ActualCompletionDate);
CREATE INDEX IDX_RepairRequests_Building ON RepairRequests(BuildingID);
CREATE INDEX IDX_RepairRequests_Employee ON RepairRequests(AssignedToEmployeeID);
CREATE INDEX IDX_RequestHistory_Request ON RequestHistory(RequestID);
GO

-- Хранимая процедура для генерации номера заявки
CREATE PROCEDURE dbo.GenerateRequestNumber
    @RequestNumber NVARCHAR(20) OUTPUT
AS
BEGIN
    DECLARE @Year INT = YEAR(GETDATE());
    DECLARE @Month INT = MONTH(GETDATE());
    DECLARE @Day INT = DAY(GETDATE());
    DECLARE @RandomNumber INT = ABS(CHECKSUM(NEWID())) % 10000;
    
    SET @RequestNumber = 'Z-' + CAST(@Year AS NVARCHAR(4)) + 
                        RIGHT('0' + CAST(@Month AS NVARCHAR(2)), 2) +
                        RIGHT('0' + CAST(@Day AS NVARCHAR(2)), 2) + 
                        '-' + RIGHT('0000' + CAST(@RandomNumber AS NVARCHAR(4)), 4);
END;
GO

-- Исправленный триггер
CREATE TRIGGER TR_RepairRequests_LogHistory
ON RepairRequests
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(Status)
    BEGIN
        INSERT INTO RequestHistory (RequestID, EmployeeID, ActionType, 
                                   OldStatus, NewStatus, Description)
        SELECT 
            i.RequestID,
            COALESCE(i.AssignedToEmployeeID, i.CreatedByEmployeeID, 1),
            'Изменение статуса',
            d.Status,
            i.Status,
            'Статус заявки изменен'
        FROM inserted i
        INNER JOIN deleted d ON i.RequestID = d.RequestID
        WHERE i.Status <> d.Status;
    END
END;
GO

-- Заполнение данными
PRINT 'Начало заполнения данных...';
GO

-- ЗАПОЛНЕНИЕ ДОМОВ
INSERT INTO Buildings (Address, Floors, ApartmentsCount, YearBuilt, TotalArea, ManagementStartDate)
VALUES 
    ('ул. 45 Параллель, 4/2, Ставрополь', 9, 52, 2001, 1978.7, '2015-04-22'),
    ('ул. Васильева, 1, Ставрополь', 9, 144, 1983, 7950.4, '2015-04-22'),
    ('ул. Доваторцев, 66/2, Ставрополь', 9, 102, 1984, 3176.4, '2020-11-01'),
    ('ул. Мира, 236, Ставрополь', 10, 62, 1991, 4423.1, '2007-11-04'),
    ('ул. Мира, 272, Ставрополь', 9, 88, 2006, 6204.7, '2015-04-22'),
    ('ул. Мира, 278, Ставрополь', 10, 40, 2008, 3294.1, '2019-08-01'),
    ('пл. Выставочная, 40, Светлоград', 5, 70, 1985, 2369.2, '2018-12-01'),
    ('пл. Выставочная, 43, Светлоград', 5, 68, 1987, 3702.8, '2019-07-01'),
    ('пл. Выставочная, 45, Светлоград', 4, 68, 1990, 3731.5, '2019-12-01'),
    ('пл. Выставочная, 47, Светлоград', 5, 68, 1993, 4079.2, '2019-07-01'),
    ('пл. Выставочная, 48, Светлоград', 5, 68, 1995, 3654.6, '2018-12-01'),
    ('пл. Выставочная, 49, Светлоград', 5, 60, 1995, 2891.7, '2021-06-01'),
    ('пл. Выставочная, 50, Светлоград', 5, 60, 1995, 4014.5, '2019-02-01'),
    ('пл. Выставочная, 57, Светлоград', 3, 36, 2015, 2075.7, '2020-02-01'),
    ('пл. Выставочная, 58, Светлоград', 5, 0, 2013, 3124.2, '2021-11-01'),
    ('ул. Бассейная, 82, Светлоград', 5, 48, 1988, 3255.3, '2021-03-01'),
    ('ул. Красная, 44а, Светлоград', 5, 60, 1983, 4317.4, '2022-03-01'),
    ('ул. Матросова, 179а, Светлоград', 4, 28, 1979, 879.4, '2022-02-18'),
    ('ул. Пушкина, 12, Светлоград', 5, 118, 1980, 5316.8, '2020-10-01'),
    ('ул. Пушкина, 3а, Светлоград', 5, 48, 1990, 1007.9, '2018-12-01'),
    ('ул. Ярмарочная, 21, Светлоград', 5, 58, 1985, 2586.6, '2021-01-01');
GO

PRINT 'Добавлено домов: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ЗАПОЛНЕНИЕ КВАРТИР ДЛЯ ДОМА ул. Матросова, 179а, Светлоград
DECLARE @BuildingID INT;
SELECT @BuildingID = BuildingID FROM Buildings WHERE Address = 'ул. Матросова, 179а, Светлоград';

INSERT INTO Apartments (BuildingID, ApartmentNumber, OwnerFullName, Phone, Area, RoomsCount)
VALUES 
    (@BuildingID, 1, 'Шевченко Ольга Викторовна', '+79180000001', 45.5, 2),
    (@BuildingID, 2, 'Мазалова Ирина Львовна', '+79185647218', 48.2, 2),
    (@BuildingID, 3, 'Семеняка Юрий Геннадьевич', '+79180000003', 42.8, 1),
    (@BuildingID, 4, 'Савельев Олег Иванович', '+79287815445', 51.3, 3),
    (@BuildingID, 5, 'Габиец Игорь Леонидович', '+79180000005', 47.6, 2),
    (@BuildingID, 6, 'Бунин Эдуард Михайлович', '+79180000006', 43.9, 2),
    (@BuildingID, 7, 'Бахшиев Павел Иннокентьевич', '+79180000007', 39.8, 1),
    (@BuildingID, 8, 'Байчорова Агата Рустамовна', '+89643324574', 52.1, 3),
    (@BuildingID, 9, 'Тюренкова Наталья Сергеевна', '+89629987214', 46.7, 2),
    (@BuildingID, 10, 'Александров Петр Константинович', '+79180000010', 44.3, 2),
    (@BuildingID, 11, 'Мазалова Ольга Николаевна', '+79180000011', 50.2, 3),
    (@BuildingID, 12, 'Лапшин Виктор Романович', '+79180000012', 41.5, 1),
    (@BuildingID, 13, 'Гусев Семен Петрович', '+89188601163', 49.8, 3),
    (@BuildingID, 14, 'Гладилина Вера Михайловна', '+79180000014', 47.2, 2),
    (@BuildingID, 15, 'Лукин Илья Федорович', '+89634568714', 43.6, 2),
    (@BuildingID, 16, 'Петров Станислав Игоревич', '+89189187845', 52.4, 3),
    (@BuildingID, 17, 'Филь Марина Федоровна', '+79180000017', 40.9, 1),
    (@BuildingID, 18, 'Михайлов Игорь Вадимович', '+79180000018', 46.1, 2),
    (@BuildingID, 19, 'Масюк Динара Викторовна', '+79180000019', 48.9, 3),
    (@BuildingID, 20, 'Мартыненко Александр Сергеевич', '+89183215428', 45.7, 2),
    (@BuildingID, 21, 'Устьянцева Анна Станиславовна', '+79180000021', 42.3, 2),
    (@BuildingID, 22, 'Антоненко Дмитрий Игоревич', '+79180000022', 51.8, 3),
    (@BuildingID, 23, 'Любяшева Галина Аркадьевна', '+89625674581', 44.5, 2),
    (@BuildingID, 24, 'Захарящев Денис Сергеевич', '+79180000024', 47.9, 2),
    (@BuildingID, 25, 'Третьяк Ярослава Викторовна', '+79180000025', 43.2, 2),
    (@BuildingID, 26, 'Бондарь Сергей Вадимович', '+79180000026', 49.5, 3),
    (@BuildingID, 27, 'Петраков Артем Сергеевич', '+79180000027', 41.8, 1),
    (@BuildingID, 28, 'Вальке Рита Владимировна', '+79180000028', 46.3, 2);
GO

PRINT 'Добавлено квартир: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ЗАПОЛНЕНИЕ СОТРУДНИКОВ
INSERT INTO Employees (LastName, FirstName, MiddleName, Position, Department, Phone, Email)
VALUES 
    ('Петров', 'Алексей', 'Иванович', 'Слесарь', 'Ремонтная служба', '+79161234501', 'petrov@company.ru'),
    ('Иванова', 'Мария', 'Сергеевна', 'Электрик', 'Ремонтная служба', '+79161234502', 'ivanova@company.ru'),
    ('Сидоров', 'Дмитрий', 'Александрович', 'Сантехник', 'Ремонтная служба', '+79161234503', 'sidorov@company.ru'),
    ('Козлова', 'Ольга', 'Викторовна', 'Диспетчер', 'Приемная', '+79161234504', 'kozlova@company.ru'),
    ('Васильев', 'Сергей', 'Петрович', 'Управляющий', 'Администрация', '+79161234505', 'vasiliev@company.ru'),
    ('Николаев', 'Андрей', 'Михайлович', 'Мастер', 'Ремонтная служба', '+79161234506', 'nikolaev@company.ru'),
    ('Федорова', 'Елена', 'Александровна', 'Бухгалтер', 'Финансовый отдел', '+79161234507', 'fedorova@company.ru');
GO

PRINT 'Добавлено сотрудников: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- ЗАПОЛНЕНИЕ ТЕСТОВЫХ ЗАЯВОК НА РЕМОНТ
DECLARE @BuildingID2 INT;
SELECT @BuildingID2 = BuildingID FROM Buildings WHERE Address = 'ул. Матросова, 179а, Светлоград';

-- Добавляем заявки
DECLARE @RequestNumber NVARCHAR(20);
DECLARE @Counter INT = 1;
DECLARE @ApartmentID INT;
DECLARE @OwnerFullName NVARCHAR(150);
DECLARE @Phone NVARCHAR(20);
DECLARE @ProblemDescription NVARCHAR(1000);
DECLARE @Priority INT;
DECLARE @Status NVARCHAR(20);
DECLARE @AssignedEmployeeID INT;
DECLARE @RequestDate DATETIME;

-- Курсор для обхода квартир
DECLARE apartment_cursor CURSOR FOR
SELECT TOP 10 ApartmentID, OwnerFullName, Phone 
FROM Apartments 
WHERE BuildingID = @BuildingID2
ORDER BY ApartmentNumber;

OPEN apartment_cursor;
FETCH NEXT FROM apartment_cursor INTO @ApartmentID, @OwnerFullName, @Phone;

WHILE @@FETCH_STATUS = 0 AND @Counter <= 10
BEGIN
    -- Генерируем номер заявки
    EXEC dbo.GenerateRequestNumber @RequestNumber OUTPUT;
    
    -- Определяем описание проблемы
    SET @ProblemDescription = CASE @Counter
        WHEN 1 THEN 'Протекает кран на кухне'
        WHEN 2 THEN 'Не работает розетка в ванной'
        WHEN 3 THEN 'Забит слив в раковине'
        WHEN 4 THEN 'Трещина в стене на балконе'
        WHEN 5 THEN 'Не закрывается входная дверь'
        WHEN 6 THEN 'Протекает радиатор отопления'
        WHEN 7 THEN 'Сломан выключатель в коридоре'
        WHEN 8 THEN 'Запах из канализационного стояка'
        WHEN 9 THEN 'Отклеиваются обои в комнате'
        ELSE 'Общее обследование помещения'
    END;
    
    -- Определяем приоритет
    SET @Priority = CASE 
        WHEN @Counter IN (1, 4) THEN 1
        WHEN @Counter IN (2, 5) THEN 2
        ELSE 3
    END;
    
    -- Определяем статус
    SET @Status = CASE 
        WHEN @Counter <= 3 THEN 'Заявка закрыта'
        WHEN @Counter <= 6 THEN 'В работе'
        ELSE 'Открыта'
    END;
    
    -- Назначаем сотрудника
    SET @AssignedEmployeeID = CASE 
        WHEN @Counter % 3 = 0 THEN 1
        WHEN @Counter % 3 = 1 THEN 2
        ELSE 3
    END;
    
    -- Устанавливаем дату
    SET @RequestDate = DATEADD(day, -@Counter, GETDATE());
    
    -- Вставляем заявку
    INSERT INTO RepairRequests (
        RequestNumber,
        BuildingID, 
        ApartmentID, 
        ApplicantFullName, 
        ApplicantPhone, 
        ProblemDescription, 
        Priority, 
        Status, 
        AssignedToEmployeeID, 
        CreatedByEmployeeID,
        RequestDate
    )
    VALUES (
        @RequestNumber,
        @BuildingID2,
        @ApartmentID,
        @OwnerFullName,
        @Phone,
        @ProblemDescription,
        @Priority,
        @Status,
        @AssignedEmployeeID,
        4, -- CreatedByEmployeeID (диспетчер)
        @RequestDate
    );
    
    SET @Counter = @Counter + 1;
    FETCH NEXT FROM apartment_cursor INTO @ApartmentID, @OwnerFullName, @Phone;
END;

CLOSE apartment_cursor;
DEALLOCATE apartment_cursor;

PRINT 'Добавлено заявок: ' + CAST(@Counter-1 AS NVARCHAR(10));
GO

-- Обновление дат для закрытых заявок
UPDATE RepairRequests 
SET ActualCompletionDate = DATEADD(day, 2, RequestDate),
    EstimatedCompletionDate = DATEADD(day, 1, RequestDate)
WHERE Status = 'Заявка закрыта';
GO

PRINT 'Обновлено закрытых заявок: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Обновление дат для заявок в работе
UPDATE RepairRequests 
SET EstimatedCompletionDate = DATEADD(day, 3, GETDATE())
WHERE Status = 'В работе';
GO

PRINT 'Обновлено заявок в работе: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Добавляем записи в историю заявок
INSERT INTO RequestHistory (RequestID, EmployeeID, ActionType, Description, OldStatus, NewStatus, ActionDate)
SELECT 
    r.RequestID,
    r.AssignedToEmployeeID,
    'Создание заявки',
    'Заявка создана диспетчером',
    NULL,
    r.Status,
    r.RequestDate
FROM RepairRequests r;
GO

PRINT 'Добавлено записей в историю: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Проверка результата
PRINT '';
PRINT '============================================';
PRINT 'РЕЗУЛЬТАТ СОЗДАНИЯ БАЗЫ ДАННЫХ:';
PRINT '============================================';

SELECT 'Дома' AS Таблица, COUNT(*) AS Количество FROM Buildings
UNION ALL
SELECT 'Квартиры', COUNT(*) FROM Apartments
UNION ALL
SELECT 'Сотрудники', COUNT(*) FROM Employees
UNION ALL
SELECT 'Заявки на ремонт', COUNT(*) FROM RepairRequests
UNION ALL
SELECT 'История заявок', COUNT(*) FROM RequestHistory;
GO

PRINT '';
PRINT 'Примеры созданных заявок:';
SELECT TOP 5 RequestNumber, Status, ProblemDescription, ApplicantFullName FROM RepairRequests;
GO

PRINT '============================================';
PRINT 'БАЗА ДАННЫХ ДЛЯ УПРАВЛЯЮЩЕЙ КОМПАНИИ УСПЕШНО СОЗДАНА!';
PRINT '============================================';
GO