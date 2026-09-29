import java.math.BigDecimal;
import java.sql.*;

/**
 * Kit iBelieve 2026 — RPG — appeler la façade CALC_TARIF_RPG3 en JDBC et lire ce que le RPG a calculé.
 *
 *   IBMI_HOTE=… IBMI_USER=… IBMI_PWD=… java -cp jt400.jar AppelerFacade.java
 *
 * Pilote : JTOpen (jt400), https://github.com/IBM/JTOpen. Remplacer VOTREBIB.
 * Prérequis : 13-facades.sql.
 */
public class AppelerFacade {
    public static void main(String[] args) throws SQLException {
        String hote = System.getenv("IBMI_HOTE"), user = System.getenv("IBMI_USER"), mdp = System.getenv("IBMI_PWD");
        try (Connection cnx = DriverManager.getConnection("jdbc:as400://" + hote + ";naming=sql", user, mdp)) {
            try (CallableStatement cs = cnx.prepareCall(
                    "CALL VOTREBIB.CALC_TARIF_RPG3(?, ?, ?, ?, ?, ?)")) {
              cs.setBigDecimal(1, new BigDecimal("10000.00"));  // HT
              cs.setBigDecimal(2, new BigDecimal("5.00"));      // remise %
              for (int i = 3; i <= 5; i++)                      // OUT
                cs.registerOutParameter(i, Types.DECIMAL, 2);
              cs.registerOutParameter(6, Types.CHAR);
              cs.execute();
              System.out.println(cs.getBigDecimal(3) + " / "
                  + cs.getBigDecimal(4) + " / " + cs.getBigDecimal(5));
            }
        }
    }
}
