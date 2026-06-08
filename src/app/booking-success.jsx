import React, { useEffect } from "react";
import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import { CheckCircle, Calendar, Home } from "lucide-react-native";
import * as Notifications from "expo-notifications";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";

// Configure notifications
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export default function BookingSuccessScreen() {
  const insets = useSafeAreaInsets();
  const { bookingId } = useLocalSearchParams();

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    sendBookingNotification();
  }, []);

  const sendBookingNotification = async () => {
    try {
      const { status: existingStatus } =
        await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      if (existingStatus !== "granted") {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }

      if (finalStatus === "granted") {
        await Notifications.scheduleNotificationAsync({
          content: {
            title: "🎉 Booking Confirmed!",
            body: `Your booking #${bookingId} has been confirmed. Check your email for details.`,
            data: { bookingId },
            sound: true,
          },
          trigger: { seconds: 2 },
        });
      }
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  };

  if (!fontsLoaded) {
    return null;
  }

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />

      <View style={[styles.content, { paddingTop: insets.top + 60 }]}>
        {/* Success Icon */}
        <View style={styles.iconContainer}>
          <CheckCircle size={80} color="#34C759" fill="#34C759" />
        </View>

        {/* Success Message */}
        <Text style={styles.title}>Booking Confirmed!</Text>
        <Text style={styles.subtitle}>
          Your booking has been confirmed. Check your email for the confirmation
          details and receipt.
        </Text>

        {/* Booking ID */}
        <View style={styles.bookingIdCard}>
          <Text style={styles.bookingIdLabel}>Booking ID</Text>
          <Text style={styles.bookingIdValue}>#{bookingId}</Text>
        </View>

        {/* Next Steps */}
        <View style={styles.nextStepsCard}>
          <Text style={styles.nextStepsTitle}>What's Next?</Text>

          <View style={styles.stepItem}>
            <View style={styles.stepIcon}>
              <Text style={styles.stepNumber}>1</Text>
            </View>
            <Text style={styles.stepText}>
              You'll receive a confirmation email shortly
            </Text>
          </View>

          <View style={styles.stepItem}>
            <View style={styles.stepIcon}>
              <Text style={styles.stepNumber}>2</Text>
            </View>
            <Text style={styles.stepText}>
              Your guide will contact you 24 hours before the experience
            </Text>
          </View>

          <View style={styles.stepItem}>
            <View style={styles.stepIcon}>
              <Text style={styles.stepNumber}>3</Text>
            </View>
            <Text style={styles.stepText}>
              Prepare for an amazing adventure!
            </Text>
          </View>
        </View>
      </View>

      {/* Actions */}
      <View
        style={[styles.actionsContainer, { paddingBottom: insets.bottom + 16 }]}
      >
        <TouchableOpacity
          style={styles.primaryButton}
          onPress={() => router.push("/(tabs)/home")}
          activeOpacity={0.9}
        >
          <Home size={20} color="#FFFFFF" />
          <Text style={styles.primaryButtonText}>Back to Home</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.secondaryButton}
          onPress={() => router.push("/(tabs)/profile")}
          activeOpacity={0.9}
        >
          <Calendar size={20} color="#FF6B9D" />
          <Text style={styles.secondaryButtonText}>View My Bookings</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  content: {
    flex: 1,
    paddingHorizontal: 32,
    alignItems: "center",
  },
  iconContainer: {
    marginBottom: 32,
  },
  title: {
    fontFamily: "Fredoka_500Medium",
    fontSize: 32,
    color: "#000",
    textAlign: "center",
    marginBottom: 12,
  },
  subtitle: {
    fontFamily: "Nunito_400Regular",
    fontSize: 16,
    color: "#666",
    textAlign: "center",
    lineHeight: 24,
    marginBottom: 32,
  },
  bookingIdCard: {
    backgroundColor: "#F9FAFB",
    borderRadius: 16,
    padding: 20,
    alignItems: "center",
    marginBottom: 24,
    width: "100%",
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  bookingIdLabel: {
    fontFamily: "Nunito_500Medium",
    fontSize: 13,
    color: "#999",
    marginBottom: 8,
  },
  bookingIdValue: {
    fontFamily: "Nunito_700Bold",
    fontSize: 24,
    color: "#FF6B9D",
  },
  nextStepsCard: {
    backgroundColor: "#FFF9FA",
    borderRadius: 16,
    padding: 20,
    width: "100%",
    borderWidth: 1,
    borderColor: "#FFE5ED",
  },
  nextStepsTitle: {
    fontFamily: "Nunito_700Bold",
    fontSize: 18,
    color: "#000",
    marginBottom: 16,
  },
  stepItem: {
    flexDirection: "row",
    alignItems: "flex-start",
    marginBottom: 16,
  },
  stepIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: "#FF6B9D",
    justifyContent: "center",
    alignItems: "center",
    marginRight: 12,
  },
  stepNumber: {
    fontFamily: "Nunito_700Bold",
    fontSize: 14,
    color: "#FFFFFF",
  },
  stepText: {
    fontFamily: "Nunito_400Regular",
    fontSize: 14,
    color: "#666",
    flex: 1,
    lineHeight: 20,
    paddingTop: 4,
  },
  actionsContainer: {
    paddingHorizontal: 24,
    paddingTop: 16,
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: "#F0F0F0",
  },
  primaryButton: {
    backgroundColor: "#FF6B9D",
    borderRadius: 24,
    paddingVertical: 16,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
  },
  primaryButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FFFFFF",
  },
  secondaryButton: {
    backgroundColor: "#FFFFFF",
    borderRadius: 24,
    paddingVertical: 16,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    borderWidth: 2,
    borderColor: "#FF6B9D",
  },
  secondaryButtonText: {
    fontFamily: "Nunito_700Bold",
    fontSize: 16,
    color: "#FF6B9D",
  },
});
