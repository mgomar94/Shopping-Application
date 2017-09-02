package ucsd.shoppingApp;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import ucsd.shoppingApp.models.CategoryModel;
import ucsd.shoppingApp.models.ShoppingCartModel;

public class PersonDAO {
	
	private static final String PERSON_EXISTS_SQL = "SELECT ID FROM PERSON WHERE PERSON_NAME = ?";
	private static final String INSERT_PERSON_SQL = "INSERT INTO PERSON(person_name, age, role_id, state_id) "
			+ " VALUES(?, ?, ?, ?) ";
	private static final String GET_PERSON_ROLE = "SELECT role_name FROM ROLE R, PERSON P WHERE P.person_name = ? AND P.role_id = R.id";
	private Connection con = null;
	
	public PersonDAO(Connection con) {
		this.con = con;
	}
	
	public boolean personExists(String username) {
		boolean isExists = false;
		PreparedStatement ptst = null;
		ResultSet rs = null;
		try {
			ptst = con.prepareStatement(PERSON_EXISTS_SQL);
			ptst.setString(1, username);
			rs = ptst.executeQuery();
			if(rs.next()) {
				isExists = true;
			} else {
				isExists = false;
			}
		} catch(Exception e) {
			e.printStackTrace();
		} finally {
			try {
				if(rs != null) {
					rs.close();
				}
				if(ptst != null) {
					ptst.close();
				}
			} catch(Exception e) {
				e.printStackTrace();
			}
		}
		return isExists;
	}
	
	public int insertPerson(String username, int age, int role_id, int state_id) throws Exception {
		int rows = 0;
		PreparedStatement ptst = null;
		try {
			ptst = con.prepareStatement(INSERT_PERSON_SQL);
			ptst.setString(1, username);
			ptst.setInt(2, age);
			ptst.setInt(3, role_id);
			ptst.setInt(4, state_id);
			rows = ptst.executeUpdate();
			con.commit();
		} catch(Exception e) {
			con.rollback();
			throw e;
		} finally {
			try {
				if(ptst != null) {
					ptst.close();
				}
			} catch(Exception e) {
				throw e;
			}
		}
		return rows;
	}
	
	public String getPersonRole(String username) {
		String role = null;
		PreparedStatement ptst = null;
		ResultSet rs = null;
		try {
			ptst = con.prepareStatement(GET_PERSON_ROLE);
			ptst.setString(1, username);
			rs = ptst.executeQuery();
			if(rs.next()) {
				role = rs.getString(1);
			}
		}
		catch(Exception e) {
			e.printStackTrace();
		}
		finally {
			try {
				if(rs != null) {
					rs.close();
				}
				if(ptst != null) {
					ptst.close();
				}
			} 
			catch(Exception e) {
				e.printStackTrace();
			}
		}
		return role;
	}
	
	public int getIdfromName(String username) {
		int id = -1;
		PreparedStatement ptst = null;
		ResultSet rs = null;
		try {
			ptst = con.prepareStatement(PERSON_EXISTS_SQL);
			ptst.setString(1, username);
			rs = ptst.executeQuery();
			if(rs.next()) {
				id = rs.getInt(1);
			} else {
				id = -1;
			}
		} catch(Exception e) {
			e.printStackTrace();
		} finally {
			try {
				if(rs != null) {
					rs.close();
				}
				if(ptst != null) {
					ptst.close();
				}
			} catch(Exception e) {
				e.printStackTrace();
			}
		}
		return id;
	}
}