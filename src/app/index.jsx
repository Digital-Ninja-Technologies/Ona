import { Redirect } from "expo-router";
import { useAuth } from "@/utils/auth/useAuth";
import { View, ActivityIndicator } from "react-native";

export default function Index() {
  const { isReady, isAuthenticated } = useAuth();

  // Wait for auth to be ready
  if (!isReady) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color="#FF6B9D" />
      </View>
    );
  }

  // If authenticated, go to main app, otherwise go to onboarding
  return (
    <Redirect href={isAuthenticated ? "/(tabs)/home" : "/onboarding/welcome"} />
  );
}
