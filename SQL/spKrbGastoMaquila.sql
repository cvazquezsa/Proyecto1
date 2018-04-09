SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM SysObjects WHERE Name='spKrbGastoMaquila' AND Type='P')
	DROP PROCEDURE spKrbGastoMaquila
GO
CREATE PROCEDURE spKrbGastoMaquila
	@ID                		int,
	@Accion			char(20),
	@Base			char(20),
	@Empresa	      		char(5),
	@Usuario			char(10),
	@Modulo	      		char(5),
	@Mov	  	      		char(20),
	@MovID             		varchar(20),
	@MovTipo     		char(20),
	@MovMoneda	      		char(10),
	@MovTipoCambio	 	float,
	@Estatus	 	      	char(15),
	@EstatusNuevo	      	char(15),
	@FechaEmision		datetime,
	@FechaRegistro		datetime,
	@FechaAfectacion    		datetime,
	@Conexion			bit,
	@SincroFinal			bit,
	@Sucursal			int,
	@UtilizarID			int,
	@UtilizarMovTipo    		char(20),
	@Ok				int		OUTPUT,
	@OkRef			varchar(255)	OUTPUT
AS
BEGIN
	DECLARE 
		@KrbMaquila bit,
		@KrbProveedor varchar(20),
		@MovGenerar varchar(20) = 'Gasto Extemporaneo',
		@Concepto	varchar(50) = 'Gasto Maquila',
		@Referencia varchar(100),
		@ComsEstatus varchar(20) = 'SINAFECTAR',
		@Almacen varchar(20),
		@Condicion varchar(20),
		@importe money,
		@impuestos money,
		@Ejercicio	int,
		@Periodo	int,
		@TasaIVA float,
		@IDComs int,
		@DMov varchar(20),
		@DmovID varchar(20)
--SELECT '1'
	SELECT @TasaIVA = DefImpuesto FROM EmpresaGral WHERE Empresa = @Empresa
	SELECT @KrbMaquila = KrbMaquila, @KrbProveedor = KrbMaquilaProv, @Condicion = KrbCondicion FROM Prod WHERe ID = @ID
	SELECT @Almacen = Almacen FROM ProdD WHERE ID = @ID
	SELECT @importe = SUM(Maquila) FROM ProdD WHERE ID = @ID
	IF ISNULL(@TasaIVA,0) <> 0 SELECT @impuestos = @importe / @TasaIVA
	SELECT @Referencia = CONCAT(@Mov, ' ', @MovID)
	SELECT @Ejercicio = DATEPART(YEAR, @FechaEmision), @Periodo = DATEPART(MONTH, @FechaEmision)
	
	IF @MovTipo IN ('PROD.A', 'PROD.E') AND @Accion IN ('GENERAR', 'AFECTAR') AND @KrbMaquila = 1 AND ISNULL(@KrbProveedor,'')<>'' 
	BEGIN
		INSERT INTO Compra
			(Empresa,	Mov,		FechaEmision,	Concepto,	Moneda,		TipoCambio,		Usuario, Referencia,	Estatus,
			Directo,	Prioridad, Proveedor,		Almacen,	Condicion,	Importe,	Impuestos, OrigenTipo,	Origen,	OrigenID,
			Ejercicio,	Periodo,	Sucursal,	SucursalOrigen)
		SELECT
			@Empresa,	@MovGenerar, @FechaEmision,	@Concepto,	@MovMoneda,	@MovTipoCambio,	@Usuario, @Referencia,	@ComsEstatus,
			1,			'Normal',	@KrbProveedor,	@Almacen,	@Condicion,	@importe,	@impuestos,	@Modulo,	@Mov,	@MovID,
			@Ejercicio,	@Periodo,	@Sucursal,	@Sucursal

		SELECT @IDComs = SCOPE_IDENTITY()

		INSERT INTO CompraD
			(ID,	Renglon,	RenglonID,	RenglonTipo,	Cantidad,	Almacen,	Articulo,	SubCuenta,	Costo,		Impuesto1,
			Unidad,	Factor, Sucursal, SucursalOrigen)
		SELECT
			@IDComs, Renglon,	RenglonID,	RenglonTipo,	Cantidad,	Almacen,	Articulo,	SubCuenta,	ManoObra,	@TasaIVA,
			Unidad,	Factor, @Sucursal,	@Sucursal
			FROM ProdD
			WHERE ID=@ID AND ISNULL(ManoObra,0) > 0
		--EXEC spVerVencimiento 'COMS', @Empresa, @KrbProveedor, @Condicion, @FechaEmision
		EXEC spAfectar 'COMS', @IdComs, 'AFECTAR', 'Todo', NULL, @Usuario, @SincroFinal, 1, @Ok OUTPUT, @OkRef OUTPUT,@FechaRegistro, @Conexion
		IF @Ok IS NULL OR @Ok BETWEEN 80030 AND 81000
		BEGIN
			SELECT @Dmov=Mov, @DmovID=MovID FROM Compra WHERE Id=@IDComs
			EXEC spMovFlujo @sucursal, @Accion, @Empresa, @Modulo, @ID, @Mov, @MovID, 'COMS', @IDComs, @DMov, @DMovID, @Ok OUTPUT
		END
		--SELECT * FROm Comprad Order BY Id DEsc

	END
END
GO