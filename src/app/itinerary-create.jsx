import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Dimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft, Sparkles, Calendar, Plus, X } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useAuth } from "@/utils/auth/useAuth";
import { useTheme } from "@/utils/theme/useTheme";
import analytics from "@/utils/analytics";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const IS_TABLET = SCREEN_WIDTH >= 768;

const durations = [
  { id: 1, label: "1 Day" },
  { id: 3, label: "3 Days" },
  { id: 5, label: "5 Days" },
  { id: 7, label: "7 Days" },
  { id: 10, label: "10 Days" },
  { id: 14, label: "2 Weeks" },
];

const budgets = [
  { id: "budget", label: "Budget", icon: "$" },
  { id: "moderate", label: "Moderate", icon: "$$" },
  { id: "luxury", label: "Luxury", icon: "$$$" },
];

export default function ItineraryCreateScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { user } = useAuth();
  const { destinationId, destinationName } = useLocalSearchParams();

  // State for mode selection
  const [creationMode, setCreationMode] = useState(null); // 'ai' or 'manual'

  // AI mode states
  const [destination, setDestination] = useState(destinationName || "");
  const [selectedDuration, setSelectedDuration] = useState(3);
  const [customDays, setCustomDays] = useState(""); // Custom days input
  const [selectedBudget, setSelectedBudget] = useState("moderate");
  const [loading, setLoading] = useState(false);
  const [generatedItinerary, setGeneratedItinerary] = useState("");
  const [error, setError] = useState(null);

  // Manual mode states
  const [manualTitle, setManualTitle] = useState("");
  const [manualDescription, setManualDescription] = useState("");
  const [manualDays, setManualDays] = useState([{ day: 1, activities: [""] }]);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    if (creationMode) {
      setCreationMode(null);
    } else {
      router.back();
    }
  };

  const handleAIGenerate = async () => {
    if (!destination.trim()) return;

    // Use custom days if entered, otherwise use selected duration
    const daysToUse = customDays.trim()
      ? parseInt(customDays)
      : selectedDuration;

    if (isNaN(daysToUse) || daysToUse < 1) return;

    try {
      setLoading(true);
      analytics.trackFeatureUse("ai_itinerary_generate", {
        destination,
        duration: daysToUse,
        budget: selectedBudget,
      });

      const response = await fetch("/api/itineraries/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          destinationName: destination,
          durationDays: daysToUse,
          budget: selectedBudget,
          interests: [],
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to generate itinerary");
      }

      const data = await response.json();
      setGeneratedItinerary(data.itinerary);

      analytics.trackEvent(
        "ai_itinerary_generated",
        {
          destination,
          duration: daysToUse,
        },
        "content",
      );
    } catch (error) {
      console.error("Error generating itinerary:", error);
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleAISave = async () => {
    if (!generatedItinerary || !destination.trim()) return;

    const daysToUse = customDays.trim()
      ? parseInt(customDays)
      : selectedDuration;

    try {
      const response = await fetch("/api/itineraries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user?.id || null,
          destinationId: destinationId || null,
          title: `${destination} - ${daysToUse} Days`,
          description: generatedItinerary,
          durationDays: daysToUse,
          isAiGenerated: true,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to save itinerary");
      }

      analytics.trackEvent(
        "itinerary_saved",
        {
          type: "ai",
          destination,
        },
        "engagement",
      );

      router.back();
    } catch (error) {
      console.error("Error saving itinerary:", error);
    }
  };

  const handleManualSave = async () => {
    if (!manualTitle.trim()) return;

    try {
      const activitiesText = manualDays
        .map(
          (day) =>
            `Day ${day.day}:\n${day.activities.filter((a) => a.trim()).join("\n")}`,
        )
        .join("\n\n");

      const response = await fetch("/api/itineraries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user?.id || null,
          destinationId: destinationId || null,
          title: manualTitle,
          description: manualDescription + "\n\n" + activitiesText,
          durationDays: manualDays.length,
          isAiGenerated: false,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to save itinerary");
      }

      analytics.trackEvent(
        "itinerary_saved",
        {
          type: "manual",
          days: manualDays.length,
        },
        "engagement",
      );

      router.back();
    } catch (error) {
      console.error("Error saving itinerary:", error);
    }
  };

  const addDay = () => {
    setManualDays([
      ...manualDays,
      { day: manualDays.length + 1, activities: [""] },
    ]);
  };

  const addActivity = (dayIndex) => {
    const updatedDays = [...manualDays];
    updatedDays[dayIndex].activities.push("");
    setManualDays(updatedDays);
  };

  const updateActivity = (dayIndex, activityIndex, text) => {
    const updatedDays = [...manualDays];
    updatedDays[dayIndex].activities[activityIndex] = text;
    setManualDays(updatedDays);
  };

  const removeActivity = (dayIndex, activityIndex) => {
    const updatedDays = [...manualDays];
    updatedDays[dayIndex].activities.splice(activityIndex, 1);
    setManualDays(updatedDays);
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: IS_TABLET ? 32 : 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    backButton: {
      width: IS_TABLET ? 44 : 40,
      height: IS_TABLET ? 44 : 40,
      borderRadius: IS_TABLET ? 22 : 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 12,
    },
    headerTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: IS_TABLET ? 22 : 20,
      color: theme.text,
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: IS_TABLET ? 48 : 24,
      paddingTop: 24,
      maxWidth: IS_TABLET ? 800 : "100%",
      alignSelf: "center",
      width: "100%",
    },
    // Mode Selection Styles
    modeContainer: {
      paddingTop: 40,
    },
    modeTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: IS_TABLET ? 28 : 24,
      color: theme.text,
      textAlign: "center",
      marginBottom: 12,
    },
    modeSubtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.textSecondary,
      textAlign: "center",
      marginBottom: 40,
      lineHeight: IS_TABLET ? 26 : 22,
    },
    modeOption: {
      backgroundColor: theme.surface,
      borderRadius: 24,
      padding: IS_TABLET ? 32 : 24,
      marginBottom: 20,
      borderWidth: 2,
      borderColor: theme.border,
      alignItems: "center",
    },
    modeIconContainer: {
      width: IS_TABLET ? 80 : 64,
      height: IS_TABLET ? 80 : 64,
      borderRadius: IS_TABLET ? 40 : 32,
      backgroundColor: "#FF6B9D",
      justifyContent: "center",
      alignItems: "center",
      marginBottom: 16,
    },
    modeOptionTitle: {
      fontFamily: "Nunito_700Bold",
      fontSize: IS_TABLET ? 22 : 18,
      color: theme.text,
      marginBottom: 8,
    },
    modeOptionDescription: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      textAlign: "center",
      lineHeight: IS_TABLET ? 24 : 20,
    },
    // Common Styles
    section: {
      marginBottom: 32,
    },
    sectionTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: theme.text,
      marginBottom: 12,
    },
    input: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: IS_TABLET ? 16 : 14,
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.text,
      borderWidth: 1,
      borderColor: theme.border,
    },
    textArea: {
      height: IS_TABLET ? 120 : 100,
      textAlignVertical: "top",
    },
    durationGrid: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 12,
    },
    durationChip: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingVertical: IS_TABLET ? 14 : 12,
      paddingHorizontal: IS_TABLET ? 22 : 20,
      borderWidth: 2,
      borderColor: "transparent",
    },
    durationChipSelected: {
      backgroundColor: "#FF6B9D",
      borderColor: "#E5528A",
    },
    durationText: {
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.text,
    },
    durationTextSelected: {
      color: "#FFFFFF",
    },
    customDaysContainer: {
      marginTop: 16,
    },
    customDaysLabel: {
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 15 : 13,
      color: theme.textSecondary,
      marginBottom: 8,
      textAlign: "center",
    },
    customDaysInput: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: IS_TABLET ? 16 : 14,
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 17 : 15,
      color: theme.text,
      borderWidth: 2,
      borderColor: customDays.trim() ? "#FF6B9D" : theme.border,
      textAlign: "center",
    },
    budgetContainer: {
      flexDirection: "row",
      gap: 12,
    },
    budgetCard: {
      flex: 1,
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: IS_TABLET ? 20 : 16,
      alignItems: "center",
      borderWidth: 2,
      borderColor: "transparent",
    },
    budgetCardSelected: {
      backgroundColor: "#FF6B9D",
      borderColor: "#E5528A",
    },
    budgetIcon: {
      fontSize: IS_TABLET ? 28 : 24,
      marginBottom: 8,
    },
    budgetLabel: {
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.text,
    },
    budgetLabelSelected: {
      color: "#FFFFFF",
    },
    generateButton: {
      backgroundColor: "#FF6B9D",
      borderRadius: 24,
      paddingVertical: IS_TABLET ? 18 : 16,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      marginBottom: 24,
    },
    generateButtonDisabled: {
      backgroundColor: theme.surface,
    },
    generateButtonText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: "#FFFFFF",
      marginLeft: 8,
    },
    generateButtonTextDisabled: {
      color: theme.textSecondary,
    },
    resultContainer: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: IS_TABLET ? 24 : 20,
      borderWidth: 1,
      borderColor: theme.border,
      marginBottom: 20,
    },
    resultTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: theme.text,
      marginBottom: 12,
    },
    resultText: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      lineHeight: IS_TABLET ? 24 : 22,
    },
    saveButton: {
      backgroundColor: "#FF6B9D",
      borderRadius: 24,
      paddingVertical: IS_TABLET ? 18 : 16,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
    },
    saveButtonText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: "#FFFFFF",
      marginLeft: 8,
    },
    loadingContainer: {
      alignItems: "center",
      justifyContent: "center",
      paddingVertical: 40,
    },
    loadingText: {
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.textSecondary,
      marginTop: 12,
    },
    // Manual Creation Styles
    dayCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: IS_TABLET ? 20 : 16,
      marginBottom: 16,
      borderWidth: 1,
      borderColor: theme.border,
    },
    dayHeader: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 18 : 16,
      color: theme.text,
      marginBottom: 12,
    },
    activityRow: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 8,
      gap: 8,
    },
    activityInput: {
      flex: 1,
      backgroundColor: theme.background,
      borderRadius: 12,
      paddingHorizontal: 12,
      paddingVertical: IS_TABLET ? 12 : 10,
      fontFamily: "Nunito_400Regular",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.text,
      borderWidth: 1,
      borderColor: theme.border,
    },
    removeActivityButton: {
      width: IS_TABLET ? 36 : 32,
      height: IS_TABLET ? 36 : 32,
      borderRadius: IS_TABLET ? 18 : 16,
      backgroundColor: theme.background,
      justifyContent: "center",
      alignItems: "center",
    },
    addActivityButton: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      paddingVertical: IS_TABLET ? 12 : 10,
      marginTop: 8,
    },
    addActivityText: {
      fontFamily: "Nunito_500Medium",
      fontSize: IS_TABLET ? 15 : 13,
      color: "#FF6B9D",
      marginLeft: 6,
    },
    addDayButton: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingVertical: IS_TABLET ? 16 : 14,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      marginBottom: 24,
      borderWidth: 2,
      borderStyle: "dashed",
      borderColor: theme.border,
    },
    addDayText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: IS_TABLET ? 16 : 14,
      color: theme.text,
      marginLeft: 8,
    },
  });

  // Mode selection screen
  if (!creationMode) {
    return (
      <View style={styles.container}>
        <StatusBar style={theme.statusBarStyle} />

        <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
          <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
            <ArrowLeft size={24} color={theme.icon} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Create Itinerary</Text>
        </View>

        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={[
            styles.contentContainer,
            { paddingBottom: insets.bottom + 20 },
          ]}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.modeContainer}>
            <Text style={styles.modeTitle}>How would you like to create?</Text>
            <Text style={styles.modeSubtitle}>
              Choose between AI-powered curation or create your own custom
              itinerary
            </Text>

            <TouchableOpacity
              style={styles.modeOption}
              onPress={() => {
                setCreationMode("ai");
                analytics.trackFeatureUse("itinerary_mode_selected", {
                  mode: "ai",
                });
              }}
              activeOpacity={0.9}
            >
              <View style={styles.modeIconContainer}>
                <Sparkles size={IS_TABLET ? 40 : 32} color="#FFFFFF" />
              </View>
              <Text style={styles.modeOptionTitle}>AI-Curated Itinerary</Text>
              <Text style={styles.modeOptionDescription}>
                Let AI create a personalized itinerary based on your
                preferences, budget, and travel style
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modeOption}
              onPress={() => {
                setCreationMode("manual");
                analytics.trackFeatureUse("itinerary_mode_selected", {
                  mode: "manual",
                });
              }}
              activeOpacity={0.9}
            >
              <View
                style={[
                  styles.modeIconContainer,
                  { backgroundColor: "#34C759" },
                ]}
              >
                <Calendar size={IS_TABLET ? 40 : 32} color="#FFFFFF" />
              </View>
              <Text style={styles.modeOptionTitle}>Manual Creation</Text>
              <Text style={styles.modeOptionDescription}>
                Build your itinerary from scratch with complete control over
                every detail
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>
    );
  }

  // AI Mode
  if (creationMode === "ai") {
    return (
      <View style={styles.container}>
        <StatusBar style={theme.statusBarStyle} />

        <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
          <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
            <ArrowLeft size={24} color={theme.icon} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>AI-Curated Itinerary</Text>
        </View>

        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={[
            styles.contentContainer,
            { paddingBottom: insets.bottom + 20 },
          ]}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Where are you going?</Text>
            <TextInput
              style={styles.input}
              value={destination}
              onChangeText={setDestination}
              placeholder="Enter destination..."
              placeholderTextColor={theme.textSecondary}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Trip Duration</Text>
            <View style={styles.durationGrid}>
              {durations.map((duration) => (
                <TouchableOpacity
                  key={duration.id}
                  style={[
                    styles.durationChip,
                    selectedDuration === duration.id &&
                      !customDays.trim() &&
                      styles.durationChipSelected,
                  ]}
                  onPress={() => {
                    setSelectedDuration(duration.id);
                    setCustomDays("");
                  }}
                >
                  <Text
                    style={[
                      styles.durationText,
                      selectedDuration === duration.id &&
                        !customDays.trim() &&
                        styles.durationTextSelected,
                    ]}
                  >
                    {duration.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={styles.customDaysContainer}>
              <Text style={styles.customDaysLabel}>
                Or enter custom number of days:
              </Text>
              <TextInput
                style={styles.customDaysInput}
                value={customDays}
                onChangeText={setCustomDays}
                placeholder="e.g., 4"
                placeholderTextColor={theme.textSecondary}
                keyboardType="number-pad"
                maxLength={3}
              />
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Budget</Text>
            <View style={styles.budgetContainer}>
              {budgets.map((budget) => (
                <TouchableOpacity
                  key={budget.id}
                  style={[
                    styles.budgetCard,
                    selectedBudget === budget.id && styles.budgetCardSelected,
                  ]}
                  onPress={() => setSelectedBudget(budget.id)}
                >
                  <Text style={styles.budgetIcon}>{budget.icon}</Text>
                  <Text
                    style={[
                      styles.budgetLabel,
                      selectedBudget === budget.id &&
                        styles.budgetLabelSelected,
                    ]}
                  >
                    {budget.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <TouchableOpacity
            style={[
              styles.generateButton,
              (!destination.trim() || loading) && styles.generateButtonDisabled,
            ]}
            onPress={handleAIGenerate}
            disabled={!destination.trim() || loading}
          >
            {loading ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <>
                <Sparkles size={20} color="#FFFFFF" />
                <Text style={styles.generateButtonText}>Generate with AI</Text>
              </>
            )}
          </TouchableOpacity>

          {error && (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>{error}</Text>
            </View>
          )}

          {loading && (
            <View style={styles.loadingContainer}>
              <Text style={styles.loadingText}>
                Creating your perfect itinerary...
              </Text>
            </View>
          )}
        </ScrollView>
      </View>
    );
  }

  // Manual Mode
  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Manual Creation</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Trip Title</Text>
          <TextInput
            style={styles.input}
            value={manualTitle}
            onChangeText={setManualTitle}
            placeholder="e.g., Paris Adventure 2025"
            placeholderTextColor={theme.textSecondary}
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Description (Optional)</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={manualDescription}
            onChangeText={setManualDescription}
            placeholder="Add a description of your trip..."
            placeholderTextColor={theme.textSecondary}
            multiline
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Daily Plan</Text>
          {manualDays.map((day, dayIndex) => (
            <View key={dayIndex} style={styles.dayCard}>
              <Text style={styles.dayHeader}>Day {day.day}</Text>
              {day.activities.map((activity, activityIndex) => (
                <View key={activityIndex} style={styles.activityRow}>
                  <TextInput
                    style={styles.activityInput}
                    value={activity}
                    onChangeText={(text) =>
                      updateActivity(dayIndex, activityIndex, text)
                    }
                    placeholder="Add activity..."
                    placeholderTextColor={theme.textSecondary}
                  />
                  {day.activities.length > 1 && (
                    <TouchableOpacity
                      style={styles.removeActivityButton}
                      onPress={() => removeActivity(dayIndex, activityIndex)}
                    >
                      <X size={16} color="#FF3B30" />
                    </TouchableOpacity>
                  )}
                </View>
              ))}
              <TouchableOpacity
                style={styles.addActivityButton}
                onPress={() => addActivity(dayIndex)}
              >
                <Plus size={16} color="#FF6B9D" />
                <Text style={styles.addActivityText}>Add Activity</Text>
              </TouchableOpacity>
            </View>
          ))}

          <TouchableOpacity style={styles.addDayButton} onPress={addDay}>
            <Plus size={20} color={theme.icon} />
            <Text style={styles.addDayText}>Add Another Day</Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          style={[
            styles.saveButton,
            !manualTitle.trim() && styles.generateButtonDisabled,
          ]}
          onPress={handleManualSave}
          disabled={!manualTitle.trim()}
        >
          <Calendar size={20} color="#FFFFFF" />
          <Text style={styles.saveButtonText}>Save Itinerary</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}
