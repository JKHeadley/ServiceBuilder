param($database_connection_string)
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Data Source=(localdb)\v11.0;Initial Catalog=CAPSLock3.0;Persist Security Info=True;MultipleActiveResultSets=True"
$conn.open()
$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.connection = $conn

$cmd.commandtext = "CREATE TABLE [dbo].[LogEventType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NULL,
 CONSTRAINT [PK_dbo.LogEventType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"
$cmd.executenonquery()

$cmd.commandtext = "INSERT INTO LogEventType (name) VALUES('{0}')" -f "Create"
$cmd.executenonquery()
$cmd.commandtext = "INSERT INTO LogEventType (name) VALUES('{0}')" -f "Update"
$cmd.executenonquery()
$cmd.commandtext = "INSERT INTO LogEventType (name) VALUES('{0}')" -f "Delete"
$cmd.executenonquery()
$cmd.commandtext = "INSERT INTO LogEventType (name) VALUES('{0}')" -f "Error"
$cmd.executenonquery()

$cmd.commandtext = "CREATE TABLE [dbo].[LogEvent](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LogEventTypeId] [int] NOT NULL,
	[LogEventTypeName] [nvarchar](50) NOT NULL,
	[EntityType] [nvarchar](50) NOT NULL,
	[EntityId] [nvarchar](50) NOT NULL,
	[ChangedByUserId] [nvarchar](50) NOT NULL,
	[ChangedByUserName] [nvarchar](50) NOT NULL,
	[Date] [datetime] NOT NULL,
	[PropertyName] [nvarchar](50) NULL,
	[PropertyType] [nvarchar](50) NULL,
	[OldValue] [nvarchar](max) NULL,
	[NewValue] [nvarchar](max) NULL,
	[ErrorMessage] [nvarchar](max) NULL,
	[StackTrace] [nvarchar](max) NULL,
 CONSTRAINT [PK_dbo.LogEvent] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"
$cmd.executenonquery()

$cmd.commandtext = "ALTER TABLE [dbo].[LogEvent]  WITH CHECK ADD  CONSTRAINT [FK_LogEvent_LogEventType] FOREIGN KEY([LogEventTypeId])
REFERENCES [dbo].[LogEventType] ([Id])"
$cmd.executenonquery()

$cmd.commandtext = "ALTER TABLE [dbo].[LogEvent] CHECK CONSTRAINT [FK_LogEvent_LogEventType]"
$cmd.executenonquery()

$conn.close()