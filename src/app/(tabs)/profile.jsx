import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Dimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  Settings,
  Heart,
  Bookmark,
  MapPin,
  Calendar,
  Crown,
  LogOut,
  ChevronRight,
  Bell,
} from "lucide-react-native";
import * as Notifications from "expo-notifications";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import { useAuth } from "@/utils/auth/useAuth";
import useSubscription from "@/utils/use-subscription";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const IS_TABLET = SCREEN_WIDTH >= 768;

export default function ProfileScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { user, signOut } = useAuth();
  const { isSubscribed, loading, initiateSubscription } = useSubscription();
  const [notificationsEnabled, setNotificationsEnabled] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    checkNotificationPermissions();
  }, []);

  const checkNotificationPermissions = async () => {
    const { status } = await Notifications.getPermissionsAsync();
    setNotificationsEnabled(status === "granted");
  };

  const toggleNotifications = async () => {
    if (notificationsEnabled) {
      Alert.alert(
        "Notifications",
        "To disable notifications, please go to your device settings.",
      );
    } else {
      const { status } = await Notifications.requestPermissionsAsync();
      setNotificationsEnabled(status === "granted");
    }
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleSignOut = async () => {
    await signOut();
  };

  const getUserInitial = () => {
    if (user?.name) {
      return user.name.charAt(0).toUpperCase();
    }
    if (user?.email) {
      return user.email.charAt(0).toUpperCase();
    }
    return "T";
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      paddingBottom: IS_TABLET ? 32 : 24,
      alignItems: "center",
    },
    avatar: {
      width: IS_TABLET ? 120 : 100,
      height: IS_TABLET ? 120 : 100,
      borderRadius: IS_TABLET ? 60 : 50,
      backgroundColor: theme.accent,
      justifyContent: "center",
      alignItems: "center",
      marginBottom: IS_TABLET ? 20 : 16,
    },
    avatarText: {
      fontFamily: "Fredoka_500Medium",
      fontSize: IS_TABLET ? 48 : 40,
      color: "#1A1A1A",
    },
    name: {
      fontFamily: "Fredoka_500Medium",
      fontSize: IS_TABLET ? 28 : 24,
      color: theme.text,
      marginBottom: 4,
    },
    email: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      marginBottom: 16,
    },
    premiumBadge: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.accent,
      borderRadius: 20,
      paddingVertical: IS_TABLET ? 8 : 6,
      paddingHorizontal: IS_TABLET ? 18 : 14,
    },
    premiumText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 15 : 13,
      color: "#1A1A1A",
      marginLeft: 6,
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      maxWidth: IS_TABLET ? 800 : "100%",
      alignSelf: "center",
      width: "100%",
    },
    upgradeCard: {
      backgroundColor: theme.surface,
      borderRadius: 20,
      padding: IS_TABLET ? 28 : 20,
      marginBottom: 24,
      borderWidth: 2,
      borderColor: theme.accent,
    },
    upgradeTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 22 : 18,
      color: theme.text,
      marginBottom: 8,
    },
    upgradeDescription: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      lineHeight: IS_TABLET ? 24 : 20,
      marginBottom: 16,
    },
    upgradeButton: {
      backgroundColor: theme.accent,
      borderRadius: 12,
      paddingVertical: IS_TABLET ? 18 : 14,
      alignItems: "center",
    },
    upgradeButtonText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 17 : 15,
      color: "#1A1A1A",
    },
    menuSection: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      overflow: "hidden",
      marginBottom: 24,
      borderWidth: 1,
      borderColor: theme.border,
    },
    menuItem: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: IS_TABLET ? 20 : 16,
      paddingHorizontal: IS_TABLET ? 20 : 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    menuItemLast: {
      borderBottomWidth: 0,
    },
    menuIcon: {
      marginRight: IS_TABLET ? 20 : 16,
    },
    menuText: {
      flex: 1,
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.text,
    },
    logoutButton: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: theme.surface,
      borderRadius: 12,
      paddingVertical: IS_TABLET ? 18 : 14,
      marginBottom: 24,
      borderWidth: 1,
      borderColor: theme.border,
    },
    logoutText: {
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 17 : 15,
      color: "#FF3B30",
      marginLeft: 8,
    },
    notificationToggle: {
      width: IS_TABLET ? 56 : 48,
      height: IS_TABLET ? 32 : 28,
      borderRadius: IS_TABLET ? 16 : 14,
      backgroundColor: "#E5E7EB",
      padding: 2,
      marginLeft: "auto",
    },
    notificationToggleActive: {
      backgroundColor: "#FF6B9D",
    },
    notificationToggleKnob: {
      width: IS_TABLET ? 28 : 24,
      height: IS_TABLET ? 28 : 24,
      borderRadius: IS_TABLET ? 14 : 12,
      backgroundColor: "#FFFFFF",
    },
    notificationToggleKnobActive: {
      transform: [{ translateX: IS_TABLET ? 24 : 20 }],
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 32 }]}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{getUserInitial()}</Text>
        </View>
        <Text style={styles.name}>{user?.name || "Traveler"}</Text>
        <Text style={styles.email}>
          {user?.email || "explorer@globemate.com"}
        </Text>

        {isSubscribed && (
          <View style={styles.premiumBadge}>
            <Crown size={16} color="#1A1A1A" />
            <Text style={styles.premiumText}>Premium Member</Text>
          </View>
        )}
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Upgrade Card */}
        {!isSubscribed && !loading && (
          <View style={styles.upgradeCard}>
            <Text style={styles.upgradeTitle}>Unlock Premium Features</Text>
            <Text style={styles.upgradeDescription}>
              Get unlimited AI itineraries, offline maps, exclusive experiences,
              and ad-free browsing.
            </Text>
            <TouchableOpacity
              style={styles.upgradeButton}
              onPress={initiateSubscription}
              activeOpacity={0.9}
            >
              <Text style={styles.upgradeButtonText}>
                Upgrade to Premium - $9.99/month
              </Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Menu Items */}
        <View style={styles.menuSection}>
          <TouchableOpacity
            style={styles.menuItem}
            onPress={() => router.push("/wishlist")}
            activeOpacity={0.7}
          >
            <Heart size={22} color="#FF6B9D" style={styles.menuIcon} />
            <Text style={styles.menuText}>My Wishlist</Text>
            <ChevronRight size={20} color={theme.iconSecondary} />
          </TouchableOpacity>

          <TouchableOpacity style={styles.menuItem} activeOpacity={0.7}>
            <Calendar size={22} color={theme.icon} style={styles.menuIcon} />
            <Text style={styles.menuText}>My Itineraries</Text>
            <ChevronRight size={20} color={theme.iconSecondary} />
          </TouchableOpacity>

          <TouchableOpacity style={styles.menuItem} activeOpacity={0.7}>
            <Bookmark size={22} color={theme.icon} style={styles.menuIcon} />
            <Text style={styles.menuText}>Saved Destinations</Text>
            <ChevronRight size={20} color={theme.iconSecondary} />
          </TouchableOpacity>

          <View style={styles.menuItem}>
            <Bell size={22} color={theme.icon} style={styles.menuIcon} />
            <Text style={styles.menuText}>Notifications</Text>
            <TouchableOpacity
              style={[
                styles.notificationToggle,
                notificationsEnabled && styles.notificationToggleActive,
              ]}
              onPress={toggleNotifications}
            >
              <View
                style={[
                  styles.notificationToggleKnob,
                  notificationsEnabled && styles.notificationToggleKnobActive,
                ]}
              />
            </TouchableOpacity>
          </View>

          <TouchableOpacity
            style={[styles.menuItem, styles.menuItemLast]}
            onPress={() => router.push("/settings")}
            activeOpacity={0.7}
          >
            <Settings size={22} color={theme.icon} style={styles.menuIcon} />
            <Text style={styles.menuText}>Settings</Text>
            <ChevronRight size={20} color={theme.iconSecondary} />
          </TouchableOpacity>
        </View>

        {/* Logout */}
        <TouchableOpacity
          style={styles.logoutButton}
          onPress={handleSignOut}
          activeOpacity={0.7}
        >
          <LogOut size={20} color="#FF3B30" />
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}
