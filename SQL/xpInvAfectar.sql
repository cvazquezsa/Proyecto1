SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE xpInvAfectar
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
AS BEGIN
IF @Ok IS NULL OR @Ok BETWEEN 80030 AND 81000
EXEC spINFORInvAfectar  @ID, @Accion, @Base, @Empresa, @Usuario, @Modulo, @Mov, @MovID, @MovTipo,
@MovMoneda, @MovTipoCambio, @Estatus, @EstatusNuevo, @FechaEmision, @FechaRegistro, @FechaAfectacion, @Conexion, @SincroFinal, @Sucursal,
NULL, NULL,@Ok OUTPUT, @OkRef OUTPUT

IF @MovTipo IN ('PROD.A', 'PROD.E') AND @Accion IN ('GENERAR', 'AFECTAR') AND  @Modulo = 'PROD' 
	AND @Ok IS NULL OR @Ok BETWEEN 80030 AND 81000
	EXEC spKrbGastoMaquila	@ID,@Accion,@Base,@Empresa,@Usuario,@Modulo,@Mov,@MovID,@MovTipo,@MovMoneda,@MovTipoCambio,
							@Estatus,@EstatusNuevo,@FechaEmision,@FechaRegistro,@FechaAfectacion,@Conexion,@SincroFinal,
							@Sucursal,@UtilizarID,@UtilizarMovTipo,@Ok OUTPUT,@OkRef OUTPUT

RETURN
END

