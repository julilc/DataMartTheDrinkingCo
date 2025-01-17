USE [master]
GO
/****** Object:  Database [dw]    Script Date: 26/6/2024 09:31:19 ******/
CREATE DATABASE [dw]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'dw', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\dw.mdf' , SIZE = 598016KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'dw_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\dw_log.ldf' , SIZE = 1515520KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [dw] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [dw].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [dw] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [dw] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [dw] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [dw] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [dw] SET ARITHABORT OFF 
GO
ALTER DATABASE [dw] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [dw] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [dw] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [dw] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [dw] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [dw] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [dw] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [dw] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [dw] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [dw] SET  ENABLE_BROKER 
GO
ALTER DATABASE [dw] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [dw] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [dw] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [dw] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [dw] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [dw] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [dw] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [dw] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [dw] SET  MULTI_USER 
GO
ALTER DATABASE [dw] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [dw] SET DB_CHAINING OFF 
GO
ALTER DATABASE [dw] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [dw] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [dw] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [dw] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'dw', N'ON'
GO
ALTER DATABASE [dw] SET QUERY_STORE = OFF
GO
USE [dw]
GO
/****** Object:  Table [dbo].[D_Descuento]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Descuento](
	[ID_Descuento] [int] IDENTITY(1,1) NOT NULL,
	[ID_Descuento_Origen] [int] NOT NULL,
	[Sistema_Origen] [varchar](50) NOT NULL,
	[F_desde] [date] NOT NULL,
	[F_hasta] [date] NULL,
	[Duracion_Descuento] [int] NULL,
	[Monto_Minimo] [float] NOT NULL,
	[Descuento (%)] [float] NOT NULL,
 CONSTRAINT [PK_D_Descuento] PRIMARY KEY CLUSTERED 
(
	[ID_Descuento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Producto]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Producto](
	[ID_Producto] [int] IDENTITY(1,1) NOT NULL,
	[Codigo_Producto] [int] NOT NULL,
	[Producto] [varchar](50) NOT NULL,
	[Categoria] [varchar](50) NOT NULL,
	[Presentacion] [varchar](50) NOT NULL,
	[Cm3] [int] NOT NULL,
	[Sistema_Origen] [varchar](50) NOT NULL,
	[Precio_Producto] [money] NOT NULL,
	[Fecha_desde_producto] [datetime] NOT NULL,
	[Fecha_hasta_producto] [datetime] NOT NULL,
 CONSTRAINT [PK_D_Producto] PRIMARY KEY CLUSTERED 
(
	[ID_Producto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[stagin_billing]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[stagin_billing] AS
	WITH TotalFactura AS (
		SELECT 
			sb.BILLING_ID, 
			SUM(DP.Precio_Producto * sb.QUANTITY) AS total_factura,
			SUM(DP.Cm3 * sb.QUANTITY) AS total_CM3,
			min(sb.DATE) as fecha_factura
		FROM stagin.dbo.billing AS sb
		JOIN D_Producto AS DP ON sb.PRODUCT_ID = DP.Codigo_Producto 
			AND sb.DATE BETWEEN DP.Fecha_desde_producto AND DP.Fecha_hasta_producto
		GROUP BY sb.BILLING_ID
	),
	MaxDescuento AS (
		SELECT
	tf.*,
    DD.ID_Descuento,
    DD.[Descuento (%)],
    max_descuento AS max_descuento
FROM TotalFactura AS tf
OUTER APPLY (
    SELECT TOP 1
        DD.ID_Descuento,
        DD.[Descuento (%)],
        MAX(DD.[Descuento (%)]) OVER () AS max_descuento
    FROM D_Descuento AS DD
    WHERE tf.total_factura >= DD.Monto_minimo
        AND tf.fecha_factura BETWEEN DD.F_desde AND DD.F_hasta
    ORDER BY DD.[Descuento (%)] DESC
) AS DD
	)

	SELECT 
		sb.BILLING_ID AS Num_Comprobante_origen, 
		sb.id_sistema_origen,
		sb.sistema_origen AS Sistema_Origen, 
		sb.fecha_sin_hora,
		sb.DATE AS Fecha_Sistema,
		sb.CUSTOMER_ID AS ID_CLIENTE, 
		sb.EMPLOYEE_ID AS ID_EMPLEADO, 
		DP.ID_Producto AS ID_PRODUCTO, 
		sb.BRANCH_ID AS Sucursal, 
		sb.hora AS H_Venta, 
		sb.QUANTITY AS Cant_Producto,
		DP.Precio_Producto AS Precio_Unitario, 
		md.ID_Descuento AS ID_Descuento, 
		md.total_factura * (md.max_descuento / 100) AS importe_descuento,
		md.total_factura - md.total_factura * (md.max_descuento / 100) AS importe_Final,
		md.total_CM3 AS CM3_Totales, 
		(CAST(md.total_CM3 AS DECIMAL(8, 1)) / 1000) AS litros_totales,
		sb.REGION,
		md.total_factura,
		md.max_descuento
	FROM stagin.dbo.billing AS sb
	JOIN D_Producto AS DP ON sb.PRODUCT_ID = DP.Codigo_Producto 
		AND sb.DATE BETWEEN DP.Fecha_desde_producto AND DP.Fecha_hasta_producto
	JOIN MaxDescuento AS md ON sb.BILLING_ID = md.BILLING_ID;
GO
/****** Object:  Table [dbo].[D_Anio]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Anio](
	[ID_Anio] [int] IDENTITY(1,1) NOT NULL,
	[Anio] [int] NOT NULL,
 CONSTRAINT [PK_D_Anio] PRIMARY KEY CLUSTERED 
(
	[ID_Anio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Categoria_Empleado]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Categoria_Empleado](
	[ID_Categoria_Empleado] [int] IDENTITY(1,1) NOT NULL,
	[Categoria_Empleado] [varchar](50) NOT NULL,
 CONSTRAINT [PK_D_Categoria_Empleado] PRIMARY KEY CLUSTERED 
(
	[ID_Categoria_Empleado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Cliente]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Cliente](
	[ID_Cliente] [int] IDENTITY(1,1) NOT NULL,
	[ID_Cliente_Origen] [int] NOT NULL,
	[Nombre] [varchar](50) NOT NULL,
	[Apellido] [varchar](50) NOT NULL,
	[Fecha_Nacimiento] [date] NOT NULL,
	[Tipo_Cliente] [varchar](50) NOT NULL,
	[Zip_Code] [varchar](50) NOT NULL,
	[Ciudad] [varchar](50) NOT NULL,
	[Estado] [varchar](50) NOT NULL,
	[Sistema_Origen] [varchar](50) NOT NULL,
 CONSTRAINT [PK_D_Cliente] PRIMARY KEY CLUSTERED 
(
	[ID_Cliente] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Dia]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Dia](
	[ID_Dia] [int] IDENTITY(1,1) NOT NULL,
	[Dia] [int] NOT NULL,
 CONSTRAINT [PK_D_Dia] PRIMARY KEY CLUSTERED 
(
	[ID_Dia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Dia_Semana]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Dia_Semana](
	[ID_Dia_Sem] [int] IDENTITY(1,1) NOT NULL,
	[Dìa_Semana] [varchar](50) NOT NULL,
 CONSTRAINT [PK_D_Dia_Semana] PRIMARY KEY CLUSTERED 
(
	[ID_Dia_Sem] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Empleado]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Empleado](
	[ID_Empleado] [int] IDENTITY(1,1) NOT NULL,
	[Legajo_Empleado] [int] NOT NULL,
	[Nombre] [varchar](50) NOT NULL,
	[Apellido] [varchar](50) NOT NULL,
	[Genero] [varchar](50) NOT NULL,
	[F_ingreso] [date] NOT NULL,
	[F_nacimiento] [date] NOT NULL,
	[Nivel_educativo] [varchar](50) NOT NULL,
	[ID_Categoria_Empleado] [int] NOT NULL,
	[Sistema_Origen] [varchar](50) NOT NULL,
	[fecha_desde_version] [date] NOT NULL,
	[fecha_hasta_version] [date] NOT NULL,
	[version] [int] NOT NULL,
 CONSTRAINT [PK_D_Empleado] PRIMARY KEY CLUSTERED 
(
	[ID_Empleado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Fecha]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Fecha](
	[Fecha] [date] NOT NULL,
	[ID_Dia] [int] NOT NULL,
	[ID_Mes] [int] NOT NULL,
	[ID_Anio] [int] NOT NULL,
	[ID_Dia_Sem] [int] NOT NULL,
	[Feriado] [varchar](50) NOT NULL,
 CONSTRAINT [PK_D_Fecha] PRIMARY KEY CLUSTERED 
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Geografia]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Geografia](
	[Zip_Code] [varchar](50) NOT NULL,
	[Ciudad] [varchar](50) NOT NULL,
	[Estado] [varchar](50) NOT NULL,
	[Region] [varchar](50) NOT NULL,
 CONSTRAINT [PK_D_Geografia] PRIMARY KEY CLUSTERED 
(
	[Zip_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[D_Mes]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[D_Mes](
	[ID_Mes] [int] IDENTITY(1,1) NOT NULL,
	[Mes] [int] NOT NULL,
	[Nombre_mes] [varchar](50) NOT NULL,
	[Trimestre] [int] NOT NULL,
	[Semestre] [int] NOT NULL,
 CONSTRAINT [PK_D_Mes] PRIMARY KEY CLUSTERED 
(
	[ID_Mes] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[F_Venta]    Script Date: 26/6/2024 09:31:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[F_Venta](
	[ID_Venta] [int] IDENTITY(1,1) NOT NULL,
	[ID_Sistema_Origen] [varchar](50) NOT NULL,
	[Num_Comprobante_origen] [varchar](50) NOT NULL,
	[Sistema_Origen] [varchar](50) NOT NULL,
	[Fecha] [date] NOT NULL,
	[ID_Cliente] [int] NOT NULL,
	[ID_Empleado] [int] NOT NULL,
	[ID_Producto] [int] NOT NULL,
	[Sucursal] [int] NOT NULL,
	[Region] [varchar](50) NOT NULL,
	[Fecha_Sistema] [datetime] NOT NULL,
	[H_Venta] [int] NOT NULL,
	[Cant_Producto] [int] NOT NULL,
	[Precio_Unitario] [money] NOT NULL,
	[Importe_Antes_Descuento] [money] NOT NULL,
	[ID_Descuento] [int] NOT NULL,
	[Importe_Descuento] [money] NOT NULL,
	[Importe_Final] [money] NOT NULL,
	[Cm3_Totales] [int] NOT NULL,
	[Litros_Totales] [float] NOT NULL,
 CONSTRAINT [PK_F_Venta] PRIMARY KEY CLUSTERED 
(
	[ID_Venta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Anio]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Anio] ON [dbo].[D_Anio]
(
	[Anio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Categoria_Empleado]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Categoria_Empleado] ON [dbo].[D_Categoria_Empleado]
(
	[Categoria_Empleado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_cliente_id_cliente_origen]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_cliente_id_cliente_origen] ON [dbo].[D_Cliente]
(
	[ID_Cliente_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_cliente_origen]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_cliente_origen] ON [dbo].[D_Cliente]
(
	[ID_Cliente_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Cliente]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Cliente] ON [dbo].[D_Cliente]
(
	[ID_Cliente_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Cliente_1]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [IX_D_Cliente_1] ON [dbo].[D_Cliente]
(
	[ID_Cliente_Origen] ASC,
	[Sistema_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_descuento_monto_minimo]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_descuento_monto_minimo] ON [dbo].[D_Descuento]
(
	[Monto_Minimo] ASC,
	[F_desde] ASC,
	[F_hasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Descuento]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Descuento] ON [dbo].[D_Descuento]
(
	[ID_Descuento_Origen] ASC,
	[Sistema_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Descuento_Monto_Fecha]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [IX_D_Descuento_Monto_Fecha] ON [dbo].[D_Descuento]
(
	[Monto_Minimo] ASC,
	[F_desde] ASC,
	[F_hasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Dia]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Dia] ON [dbo].[D_Dia]
(
	[Dia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Dia_Semana]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Dia_Semana] ON [dbo].[D_Dia_Semana]
(
	[Dìa_Semana] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_empleado_legajo_empleado]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_empleado_legajo_empleado] ON [dbo].[D_Empleado]
(
	[Legajo_Empleado] ASC,
	[fecha_desde_version] ASC,
	[fecha_hasta_version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Empleado]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Empleado] ON [dbo].[D_Empleado]
(
	[Legajo_Empleado] ASC,
	[Sistema_Origen] ASC,
	[fecha_desde_version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_fecha]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_fecha] ON [dbo].[D_Fecha]
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_fecha_fecha]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_fecha_fecha] ON [dbo].[D_Fecha]
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_geografia_region]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_geografia_region] ON [dbo].[D_Geografia]
(
	[Region] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Mes]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_D_Mes] ON [dbo].[D_Mes]
(
	[Mes] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_product_codigo_producto]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_product_codigo_producto] ON [dbo].[D_Producto]
(
	[Codigo_Producto] ASC,
	[Fecha_desde_producto] ASC,
	[Fecha_hasta_producto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_producto_codigo_fecha]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [idx_producto_codigo_fecha] ON [dbo].[D_Producto]
(
	[Codigo_Producto] ASC,
	[Fecha_desde_producto] ASC,
	[Fecha_hasta_producto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_D_Producto]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [IX_D_Producto] ON [dbo].[D_Producto]
(
	[Codigo_Producto] ASC,
	[Fecha_desde_producto] ASC,
	[Sistema_Origen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_D_Producto_Codigo_Fecha]    Script Date: 26/6/2024 09:31:19 ******/
CREATE NONCLUSTERED INDEX [IX_D_Producto_Codigo_Fecha] ON [dbo].[D_Producto]
(
	[Codigo_Producto] ASC,
	[Fecha_desde_producto] ASC,
	[Fecha_hasta_producto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_F_Venta]    Script Date: 26/6/2024 09:31:19 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_F_Venta] ON [dbo].[F_Venta]
(
	[Num_Comprobante_origen] ASC,
	[Sistema_Origen] ASC,
	[Fecha] ASC,
	[ID_Cliente] ASC,
	[ID_Producto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[D_Cliente]  WITH NOCHECK ADD  CONSTRAINT [FK_D_Cliente_D_Geografia] FOREIGN KEY([Zip_Code])
REFERENCES [dbo].[D_Geografia] ([Zip_Code])
GO
ALTER TABLE [dbo].[D_Cliente] NOCHECK CONSTRAINT [FK_D_Cliente_D_Geografia]
GO
ALTER TABLE [dbo].[D_Fecha]  WITH NOCHECK ADD  CONSTRAINT [FK_D_Fecha_D_Anio] FOREIGN KEY([ID_Anio])
REFERENCES [dbo].[D_Anio] ([ID_Anio])
GO
ALTER TABLE [dbo].[D_Fecha] NOCHECK CONSTRAINT [FK_D_Fecha_D_Anio]
GO
ALTER TABLE [dbo].[D_Fecha]  WITH NOCHECK ADD  CONSTRAINT [FK_D_Fecha_D_Dia] FOREIGN KEY([ID_Dia])
REFERENCES [dbo].[D_Dia] ([ID_Dia])
GO
ALTER TABLE [dbo].[D_Fecha] NOCHECK CONSTRAINT [FK_D_Fecha_D_Dia]
GO
ALTER TABLE [dbo].[D_Fecha]  WITH NOCHECK ADD  CONSTRAINT [FK_D_Fecha_D_Dia_Semana] FOREIGN KEY([ID_Dia_Sem])
REFERENCES [dbo].[D_Dia_Semana] ([ID_Dia_Sem])
GO
ALTER TABLE [dbo].[D_Fecha] NOCHECK CONSTRAINT [FK_D_Fecha_D_Dia_Semana]
GO
ALTER TABLE [dbo].[D_Fecha]  WITH NOCHECK ADD  CONSTRAINT [FK_D_Fecha_D_Mes] FOREIGN KEY([ID_Mes])
REFERENCES [dbo].[D_Mes] ([ID_Mes])
GO
ALTER TABLE [dbo].[D_Fecha] NOCHECK CONSTRAINT [FK_D_Fecha_D_Mes]
GO
ALTER TABLE [dbo].[F_Venta]  WITH NOCHECK ADD  CONSTRAINT [FK_F_Venta_D_Cliente] FOREIGN KEY([ID_Cliente])
REFERENCES [dbo].[D_Cliente] ([ID_Cliente])
GO
ALTER TABLE [dbo].[F_Venta] NOCHECK CONSTRAINT [FK_F_Venta_D_Cliente]
GO
ALTER TABLE [dbo].[F_Venta]  WITH NOCHECK ADD  CONSTRAINT [FK_F_Venta_D_Descuento] FOREIGN KEY([ID_Descuento])
REFERENCES [dbo].[D_Descuento] ([ID_Descuento])
GO
ALTER TABLE [dbo].[F_Venta] NOCHECK CONSTRAINT [FK_F_Venta_D_Descuento]
GO
ALTER TABLE [dbo].[F_Venta]  WITH NOCHECK ADD  CONSTRAINT [FK_F_Venta_D_Fecha] FOREIGN KEY([Fecha])
REFERENCES [dbo].[D_Fecha] ([Fecha])
GO
ALTER TABLE [dbo].[F_Venta] NOCHECK CONSTRAINT [FK_F_Venta_D_Fecha]
GO
ALTER TABLE [dbo].[F_Venta]  WITH NOCHECK ADD  CONSTRAINT [FK_F_Venta_D_Geografia] FOREIGN KEY([Region])
REFERENCES [dbo].[D_Geografia] ([Zip_Code])
GO
ALTER TABLE [dbo].[F_Venta] NOCHECK CONSTRAINT [FK_F_Venta_D_Geografia]
GO
ALTER TABLE [dbo].[F_Venta]  WITH NOCHECK ADD  CONSTRAINT [FK_F_Venta_D_Producto] FOREIGN KEY([ID_Producto])
REFERENCES [dbo].[D_Producto] ([ID_Producto])
GO
ALTER TABLE [dbo].[F_Venta] NOCHECK CONSTRAINT [FK_F_Venta_D_Producto]
GO
USE [master]
GO
ALTER DATABASE [dw] SET  READ_WRITE 
GO
