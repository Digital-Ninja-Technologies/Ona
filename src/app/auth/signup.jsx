import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
} from "react-native";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { useRouter } from "expo-router";
import { Mail, Lock, User, ArrowLeft, Eye, EyeOff } from "lucide-react-native";
import {
  useFonts,
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
} from "@expo-google-fonts/poppins";
import { useAuth } from "@/utils/auth/useAuth";

export default function SignUpScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { setAuth } = useAuth();

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [fieldErrors, setFieldErrors] = useState({
    name: null,
    email: null,
    password: null,
    confirmPassword: null,
  });

  const [fontsLoaded] = useFonts({
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
  });

  if (!fontsLoaded) {
    return null;
  }

  const handleSignUp = async () => {
    if (!name || !email || !password || !confirmPassword) {
      setError("Please fill in all fields");
      return;
    }

    if (!email.includes("@")) {
      setError("Please enter a valid email");
      return;
    }

    if (password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    try {
      setLoading(true);
      setError("");

      const emailLower = email.toLowerCase().trim();
      const nameTrimmed = name.trim();

      console.log("📝 Attempting sign up...", {
        email: emailLower,
        name: nameTrimmed,
      });

      // Use full API URL for mobile app
      const apiUrl = `${process.env.EXPO_PUBLIC_BASE_URL}/api/auth/token`;
      console.log("🌐 API URL:", apiUrl);

      // Create account via credentials provider
      const signupResponse = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          provider: "credentials-signup",
          email: emailLower,
          password,
          name: nameTrimmed,
        }),
      });

      console.log("📡 Sign up response status:", signupResponse.status);

      if (!signupResponse.ok) {
        const errorData = await signupResponse.json().catch(() => ({}));
        console.error("❌ Sign up failed:", errorData);
        throw new Error(
          errorData.error ||
            "Failed to create account. Email may already be in use.",
        );
      }

      const data = await signupResponse.json();
      console.log("✅ Sign up successful:", {
        userId: data.user?.id,
        email: data.user?.email,
      });

      if (data.jwt && data.user) {
        // Set auth state
        await setAuth({
          jwt: data.jwt,
          user: data.user,
        });

        console.log("🎉 Auth state set, navigating to onboarding");

        // Navigate to onboarding
        router.replace("/onboarding/interests");
      } else {
        throw new Error("Invalid response from server");
      }
    } catch (err) {
      console.error("❌ Sign up error:", err);
      setError(err.message || "Failed to create account. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleNameChange = (text) => {
    setName(text);
    setFieldErrors({ ...fieldErrors, name: null });
  };

  const handleEmailChange = (text) => {
    setEmail(text);
    setFieldErrors({ ...fieldErrors, email: null });
  };

  const handlePasswordChange = (text) => {
    setPassword(text);
    setFieldErrors({ ...fieldErrors, password: null });
  };

  const handleConfirmPasswordChange = (text) => {
    setConfirmPassword(text);
    setFieldErrors({ ...fieldErrors, confirmPassword: null });
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {/* Background Image */}
      <Image
        source={{
          uri: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1",
        }}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        transition={100}
        pointerEvents="none"
      />

      {/* Gradient Overlay */}
      <LinearGradient
        colors={["rgba(0,0,0,0.6)", "rgba(0,0,0,0.8)", "rgba(0,0,0,0.95)"]}
        locations={[0, 0.5, 1]}
        style={StyleSheet.absoluteFill}
      />

      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <ScrollView
          contentContainerStyle={[
            styles.scrollContent,
            { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 20 },
          ]}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => router.back()}
            >
              <ArrowLeft size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>

          {/* Logo */}
          <View style={styles.logoContainer}>
            <Image
              source={{
                uri: "https://ucarecdn.com/7a3f327f-1f72-4f06-98d0-0b38dfeeb1da/",
              }}
              style={styles.logo}
              contentFit="contain"
              transition={100}
            />
          </View>

          {/* Title */}
          <Text style={styles.title}>Create Account</Text>
          <Text style={styles.subtitle}>Start your adventure today</Text>

          {/* Form */}
          <View style={styles.form}>
            {/* Name Input */}
            <View>
              <View
                style={[
                  styles.inputContainer,
                  fieldErrors.name && styles.inputContainerError,
                ]}
              >
                <User size={20} color="rgba(255, 255, 255, 0.6)" />
                <TextInput
                  style={styles.input}
                  placeholder="Full Name"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={name}
                  onChangeText={handleNameChange}
                  autoCapitalize="words"
                />
              </View>
              {fieldErrors.name ? (
                <Text style={styles.fieldErrorText}>{fieldErrors.name}</Text>
              ) : null}
            </View>

            {/* Email Input */}
            <View>
              <View
                style={[
                  styles.inputContainer,
                  fieldErrors.email && styles.inputContainerError,
                ]}
              >
                <Mail size={20} color="rgba(255, 255, 255, 0.6)" />
                <TextInput
                  style={styles.input}
                  placeholder="Email"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={email}
                  onChangeText={handleEmailChange}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                />
              </View>
              {fieldErrors.email ? (
                <Text style={styles.fieldErrorText}>{fieldErrors.email}</Text>
              ) : null}
            </View>

            {/* Password Input */}
            <View>
              <View
                style={[
                  styles.inputContainer,
                  fieldErrors.password && styles.inputContainerError,
                ]}
              >
                <Lock size={20} color="rgba(255, 255, 255, 0.6)" />
                <TextInput
                  style={styles.input}
                  placeholder="Password"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={password}
                  onChangeText={handlePasswordChange}
                  secureTextEntry={!showPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={() => setShowPassword(!showPassword)}
                  style={styles.eyeIcon}
                >
                  {showPassword ? (
                    <EyeOff size={20} color="rgba(255, 255, 255, 0.6)" />
                  ) : (
                    <Eye size={20} color="rgba(255, 255, 255, 0.6)" />
                  )}
                </TouchableOpacity>
              </View>
              {fieldErrors.password ? (
                <Text style={styles.fieldErrorText}>
                  {fieldErrors.password}
                </Text>
              ) : null}
            </View>

            {/* Confirm Password Input */}
            <View>
              <View
                style={[
                  styles.inputContainer,
                  fieldErrors.confirmPassword && styles.inputContainerError,
                ]}
              >
                <Lock size={20} color="rgba(255, 255, 255, 0.6)" />
                <TextInput
                  style={styles.input}
                  placeholder="Confirm Password"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={confirmPassword}
                  onChangeText={handleConfirmPasswordChange}
                  secureTextEntry={!showConfirmPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                  style={styles.eyeIcon}
                >
                  {showConfirmPassword ? (
                    <EyeOff size={20} color="rgba(255, 255, 255, 0.6)" />
                  ) : (
                    <Eye size={20} color="rgba(255, 255, 255, 0.6)" />
                  )}
                </TouchableOpacity>
              </View>
              {fieldErrors.confirmPassword ? (
                <Text style={styles.fieldErrorText}>
                  {fieldErrors.confirmPassword}
                </Text>
              ) : null}
            </View>

            {/* Error Message */}
            {error ? <Text style={styles.errorText}>{error}</Text> : null}

            {/* Sign Up Button */}
            <TouchableOpacity
              style={[
                styles.signUpButton,
                loading && styles.signUpButtonDisabled,
              ]}
              onPress={handleSignUp}
              disabled={loading}
              activeOpacity={0.9}
            >
              {loading ? (
                <ActivityIndicator color="#FFFFFF" />
              ) : (
                <Text style={styles.signUpButtonText}>Sign Up</Text>
              )}
            </TouchableOpacity>

            {/* Sign In Link */}
            <Text style={styles.signInText}>
              Already have an account?{" "}
              <Text
                style={styles.signInLink}
                onPress={() => router.push("/auth/signin")}
              >
                Sign In
              </Text>
            </Text>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000",
  },
  scrollContent: {
    paddingHorizontal: 24,
  },
  header: {
    marginBottom: 20,
  },
  backButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: "rgba(255, 255, 255, 0.1)",
    justifyContent: "center",
    alignItems: "center",
  },
  logoContainer: {
    alignItems: "center",
    marginBottom: 32,
  },
  logo: {
    width: 200,
    height: 66,
  },
  title: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 32,
    color: "#FFFFFF",
    marginBottom: 8,
  },
  subtitle: {
    fontFamily: "Poppins_400Regular",
    fontSize: 16,
    color: "rgba(255, 255, 255, 0.7)",
    marginBottom: 40,
  },
  form: {
    gap: 16,
  },
  inputContainer: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.1)",
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.2)",
  },
  inputContainerError: {
    borderColor: "#FF6B6B",
    borderWidth: 2,
  },
  input: {
    flex: 1,
    fontFamily: "Poppins_400Regular",
    fontSize: 16,
    color: "#FFFFFF",
    marginLeft: 12,
  },
  eyeIcon: {
    padding: 4,
  },
  fieldErrorText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 13,
    color: "#FF6B6B",
    marginTop: 6,
    marginLeft: 4,
  },
  errorText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "#FF6B6B",
    marginTop: -8,
    textAlign: "center",
  },
  signUpButton: {
    backgroundColor: "#00BFA5",
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: "center",
    marginTop: 8,
  },
  signUpButtonDisabled: {
    opacity: 0.6,
  },
  signUpButtonText: {
    fontFamily: "Poppins_600SemiBold",
    fontSize: 16,
    color: "#FFFFFF",
  },
  signInText: {
    fontFamily: "Poppins_400Regular",
    fontSize: 14,
    color: "rgba(255, 255, 255, 0.7)",
    textAlign: "center",
    marginTop: 16,
  },
  signInLink: {
    fontFamily: "Poppins_600SemiBold",
    color: "#00BFA5",
  },
});
