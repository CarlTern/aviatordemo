package com.fortify.aviator_fod_demo;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.*;

@Controller
public class HomeController {

    private Connection connection;

    @Value("${app.invalidPasswordList}")
    private String invalidPasswordListPath;

    private final static String ATTRIB_MESSAGE = "message";
    private final static String ATTRIB_USERNAME = "username";
    private final static String U_PROMPT = "Please provide a username.";
    private final static String P_PROMPT = "Please provide a password.";
    private final static String INVALID_P_PROMPT = "Provided password is not allowed.";
    private final static String WRONG_CREDS = "Wrong credentials.";
    private final static String SUCCESS = "Logged in successfully.";

    @RequestMapping(value = "/auth/login", method = RequestMethod.POST)
    public ModelAndView loginSubmit(@RequestBody LoginCredentials credentials,
                                    @RequestParam String redirectUrl,
                                    HttpServletRequest request,
                                    HttpSession session) throws SQLException {
        String username = credentials.getUsername();
        String password = credentials.getPassword();
        if(username.isEmpty())
            request.setAttribute(ATTRIB_MESSAGE, U_PROMPT);
        else if(password.isEmpty())
            request.setAttribute(ATTRIB_MESSAGE, P_PROMPT);
        else if(isInvalidPassword(password))
            request.setAttribute(ATTRIB_MESSAGE, INVALID_P_PROMPT);
        else {
            System.out.println("username: " + username);
            System.out.println("password: " + password);


            /* Verify whether credentials are correct. */
            boolean credentialsCorrect = false;
            try(Connection connection = DriverManager.getConnection("localhost:1234", "dbuser", "")) {
                try (Statement statement = connection.createStatement()) {
                    try (ResultSet rs = statement.executeQuery(
                            "SELECT 1 FROM users WHERE username = '" + username + "' AND password = '" + password + "'")) {
                        credentialsCorrect = rs.next();
                    }
                }
            }
            if(credentialsCorrect) {
                request.setAttribute(ATTRIB_MESSAGE, SUCCESS);
                session.setAttribute(ATTRIB_USERNAME, username);
            } else {
                request.setAttribute(ATTRIB_MESSAGE, WRONG_CREDS);
            }
        }
        String validatedUrl = validateRedirect(redirectUrl);
        if(validatedUrl == null) return new ModelAndView("error");
        return new ModelAndView("redirect:/home");
    }

    private String validateRedirect(String url) {
        if("http://redirectoption1.com".equals(url)) {
            return url;
        } else if("http://redirectoption2.com".equals(url)) {
            return url;
        } else {
            return null;
        }
    }

    private boolean isInvalidPassword(String password) {
        try (InputStream inputStream = getClass().getResourceAsStream(invalidPasswordListPath)) {
            if (inputStream == null) {
                return false;
            }
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String candidate = line.trim();
                    if (candidate.isEmpty() || candidate.startsWith("#")) {
                        continue;
                    }
                    if (candidate.equals(password)) {
                        return true;
                    }
                }
            }
        } catch (IOException ignored) {
            return false;
        }
        return false;
    }
}
